//
//  Server.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/20/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

open class Server {
  public weak var delegate: ServerDelegate?
  public var delegateQueue = DispatchQueue(label: "Telegraph.Server.delegate")

  public var httpConfig = HTTPConfig.serverDefault
  public var webSocketConfig = WebSocketConfig.serverDefault
  public weak var webSocketDelegate: ServerWebSocketDelegate?

  private var listener: TCPListener?
  private var tlsConfig: TLSConfig?
  private var httpConnections = SynchronizedSet<HTTPConnection>()
  private var webSocketConnections = SynchronizedSet<WebSocketConnection>()

  private let listenerQueue = DispatchQueue(label: "Telegraph.Server.listener")
  private let connectionsQueue = DispatchQueue(label: "Telegraph.Server.connections")
  private let workerQueue = OperationQueue()

  /// Initializes a unsecure Server instance.
  public init() {}

  /// Initializes a secure Server instance.
  public init(identity: CertificateIdentity, caCertificates: [Certificate]) {
    tlsConfig = TLSConfig(serverIdentity: identity, caCertificates: caCertificates)
  }

  /// Starts the server on the specified port or 0 for automatic port assignment.
  open func start(port: Endpoint.Port = 0, interface: String? = nil) throws {
    listener = TCPListener(port: port, interface: interface, tlsConfig: tlsConfig)
    listener!.delegate = self

    try listener!.start(queue: listenerQueue)
  }

  /// Stops the server, optionally we wait for requests to finish.
  open func stop(immediately: Bool = false) {
    listener?.stop()

    // Close the connections
    httpConnections.forEach { $0.close(immediately: immediately) }
    webSocketConnections.forEach { $0.close(immediately: immediately) }
  }

  /// Handles an incoming HTTP request. If an error occurs, it will call handleIncoming(error:).
  open func handleIncoming(request: HTTPRequest) throws -> HTTPResponse? {
    let response = try httpConfig.requestChain(request)

    // Check that a possible connection upgrade was handled properly
    if let response = response, response.status != .switchingProtocols, request.isConnectionUpgrade {
      throw HTTPError.protocolNotSupported
    }

    return response
  }

  /// Handles any errors while processing incoming requests.
  open func handleIncoming(error: Error) -> HTTPResponse? {
    return httpConfig.errorHandler.respond(to: error)
  }

  /// This function is called on the worker and handles the request and possible errors.
  private func workerProcess(request: HTTPRequest, error: Error?) -> HTTPResponse? {
    do {
      if let error = error { throw error }
      return try handleIncoming(request: request)
    } catch {
      return handleIncoming(error: error)
    }
  }
}

// MARK: Server properties

public extension Server {
  /// Returns the number of concurrent requests that can be handled.
  var concurrency: Int {
    get { return workerQueue.maxConcurrentOperationCount }
    set { workerQueue.maxConcurrentOperationCount = newValue }
  }

  /// Returns the port on which the listener is accepting connections.
  var port: Endpoint.Port {
    return listener?.port ?? 0
  }

  /// Returns a boolean indicating if the server is running.
  var isRunning: Bool {
    return listener?.isListening ?? false
  }

  /// Returns a boolean indicating if the server is secure (HTTPS).
  var isSecure: Bool {
    return tlsConfig != nil
  }

  /// Returns the number of active HTTP connections.
  var httpConnectionCount: Int {
    return httpConnections.count
  }

  /// Returns the number of active WebSocket connections.
  var webSocketCount: Int {
    return webSocketConnections.count
  }

  /// Returns the connected
  var webSockets: [WebSocket] {
    return webSocketConnections.toArray()
  }
}

// MARK: TCPListenerDelegate implementation

extension Server: TCPListenerDelegate {
  /// Raised when the server's listener accepts an incoming socket connection.
  public func listener(_ listener: TCPListener, didAcceptSocket socket: TCPSocket) {
    // Configure the socket
    socket.setDelegateQueue(connectionsQueue)

    // Wrap the socket in a HTTP connection
    let httpConnection = HTTPConnection(socket: socket, config: httpConfig)
    httpConnections.insert(httpConnection)

    // Open the HTTP connection
    httpConnection.delegate = self
    httpConnection.open()
  }

  /// Raised when the server's listener disconnected.
  public func listenerDisconnected(_ listener: TCPListener, error: Error?) {
    delegateQueue.async { [weak self] in
      guard let self = self else { return }
      self.delegate?.serverDidStop(self, error: error)
      self.webSocketDelegate?.serverDidDisconnect(self)
    }
  }
}

// MARK: HTTPConnectionDelegate implementation

extension Server: HTTPConnectionDelegate {
  /// Raised when a HTTP connection receives an incoming request.
  public func connection(_ httpConnection: HTTPConnection, handleIncomingRequest request: HTTPRequest, error: Error?) {
    workerQueue.addOperation { [weak self, weak httpConnection] in
      guard let self = self, let httpConnection = httpConnection else { return }

      // Get a response for the request
      let response = self.workerProcess(request: request, error: error)

      // Send the response or close the connection
      self.connectionsQueue.async {
        if let response = response {
          httpConnection.send(response: response, toRequest: request)
        } else {
          httpConnection.close(immediately: true)
        }
      }
    }
  }

  /// Raised when a HTTP connection receives an incoming response.
  public func connection(_ httpConnection: HTTPConnection, handleIncomingResponse response: HTTPResponse, error: Error?) {
    httpConnection.close(immediately: true)
  }

  /// Raised when a HTTP connection requests an connection upgrade.
  public func connection(_ httpConnection: HTTPConnection, handleUpgradeByRequest request: HTTPRequest) {
    // We can only handle the WebSocket protocol
    guard request.isWebSocketUpgrade else {
      httpConnection.close(immediately: true)
      return
    }

    // Remove the http connection
    httpConnections.remove(httpConnection)

    // Extract the socket and any WebSocket data already read
    let (socket, webSocketData) = httpConnection.upgrade()

    // Add the websocket connection
    let webSocketConnection = WebSocketConnection(socket: socket, config: webSocketConfig)
    webSocketConnections.insert(webSocketConnection)

    // Open the websocket connection
    webSocketConnection.delegate = self
    webSocketConnection.open(data: webSocketData)

    // Call the delegate
    delegateQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocketDelegate?.server(self, webSocketDidConnect: webSocketConnection, handshake: request)
    }
  }

  /// Raised when a HTTP connection closed, optionally with an error.
  public func connection(_ httpConnection: HTTPConnection, didCloseWithError error: Error?) {
    httpConnections.remove(httpConnection)
  }
}

// MARK: WebSocketConnectionDelegate implementation

extension Server: WebSocketConnectionDelegate {
  public func connection(_ webSocketConnection: WebSocketConnection, didReceiveMessage message: WebSocketMessage) {
    // Call the delegate
    delegateQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocketDelegate?.server(self, webSocket: webSocketConnection, didReceiveMessage: message)
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didSendMessage message: WebSocketMessage) {
    // Call the delegate
    delegateQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocketDelegate?.server(self, webSocket: webSocketConnection, didSendMessage: message)
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didCloseWithError error: Error?) {
    // Remove the websocket connection
    webSocketConnections.remove(webSocketConnection)

    // Call the delegate
    delegateQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocketDelegate?.server(self, webSocketDidDisconnect: webSocketConnection, error: error)
    }
  }
}
