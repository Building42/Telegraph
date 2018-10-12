//
//  Server.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/20/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

open class Server {
  public var delegateQueue = DispatchQueue(label: "Telegraph.Server.delegate")

  public var httpConfig = HTTPConfig.serverDefault
  public var webSocketConfig = WebSocketConfig.serverDefault
  public weak var webSocketDelegate: ServerWebSocketDelegate?

  private var listener: TCPListener
  private var httpConnections = SynchronizedSet<HTTPConnection>()
  private var webSocketConnections = SynchronizedSet<WebSocketConnection>()

  /// Initializes a unsecure Server instance.
  public init() {
    listener = TCPListener(tlsConfig: nil)
    listener.delegate = self
  }

  /// Initializes a secure Server instance.
  public init(identity: CertificateIdentity, caCertificates: [Certificate]) {
    listener = TCPListener(tlsConfig: TLSConfig(serverIdentity: identity, caCertificates: caCertificates))
    listener.delegate = self
  }

  /// Starts the server on the specified port.
  open func start(onPort port: UInt16 = 0) throws {
    try listener.accept(onPort: port)
  }

  /// Starts the server on the specified network interface and port.
  open func start(onInterface interface: String?, port: UInt16 = 0) throws {
    try listener.accept(onInterface: interface, port: port)
  }

  /// Stops the server, optionally we wait for requests to finish.
  open func stop(immediately: Bool = false) {
    listener.disconnect()

    // Close the connections
    httpConnections.forEach { $0.close(immediately: immediately) }
    webSocketConnections.forEach { $0.close(immediately: immediately) }
  }

  /// Returns the port on which the listener is accepting connections.
  open var port: UInt16 {
    return listener.port
  }
}

// MARK: Server properties

extension Server {
  /// Returns a boolean indicating if the server is running.
  public var isRunning: Bool {
    return listener.isAccepting
  }

  /// Returns a boolean indicating if the server is secure (HTTPS).
  public var isSecure: Bool {
    return listener.tlsConfig != nil
  }

  /// Returns the number of active HTTP connections.
  public var httpConnectionCount: Int {
    return httpConnections.count
  }

  /// Returns the number of active WebSocket connections.
  public var webSocketCount: Int {
    return webSocketConnections.count
  }

  /// Returns the connected
  public var webSockets: [WebSocket] {
    return webSocketConnections.toArray()
  }
}

// MARK: TCPListenerDelegate implementation

extension Server: TCPListenerDelegate {
  /// Raised when the server's listener accepts an incoming socket connection.
  public func listener(_ listener: TCPListener, didAcceptSocket socket: TCPSocket) {
    // Wrap the socket in a HTTP connection
    let httpConnection = HTTPConnection(socket: socket, config: httpConfig)
    httpConnections.insert(httpConnection)

    // Open the HTTP connection
    httpConnection.delegate = self
    httpConnection.open()
  }

  /// Raised when the server's listener disconnected.
  public func listenerDisconnected(_ listener: TCPListener) {
    delegateQueue.async { [weak self] in
      guard let self = self else { return }
      self.webSocketDelegate?.serverDidDisconnect(self)
    }
  }
}

// MARK: HTTPConnectionDelegate implementation

extension Server: HTTPConnectionDelegate {
  /// Raised when a HTTP connection receives an incoming request.
  public func connection(_ httpConnection: HTTPConnection, handleIncomingRequest request: HTTPRequest, error: Error?) {
    var chainResponse: HTTPResponse?

    do {
      // Let the HTTP chain handle the request
      if let error = error { throw error }
      chainResponse = try httpConfig.requestChain(request)

      // Check that a possible connection upgrade was handled properly
      if request.isConnectionUpgrade, let response = chainResponse, response.status != .switchingProtocols {
        throw HTTPError.protocolNotSupported
      }
    } catch {
      // Or pass it to the error handler if something is wrong
      chainResponse = httpConfig.errorHandler.respond(to: error)
    }

    // Send the response or close the connection
    if let response = chainResponse {
      httpConnection.send(response: response, toRequest: request)
    } else {
      httpConnection.close(immediately: true)
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

    // Add the websocket connection
    let webSocketConnection = WebSocketConnection(socket: httpConnection.socket, config: webSocketConfig)
    webSocketConnections.insert(webSocketConnection)

    // Open the websocket connection
    webSocketConnection.delegate = self
    webSocketConnection.open()

    // Call the delegate
    delegateQueue.async { [weak self, weak webSocketConnection] in
      guard let self = self, let webSocketConnection = webSocketConnection else { return }
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
    delegateQueue.async { [weak self, weak webSocketConnection] in
      guard let self = self, let webSocketConnection = webSocketConnection else { return }
      self.webSocketDelegate?.server(self, webSocket: webSocketConnection, didReceiveMessage: message)
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didSendMessage message: WebSocketMessage) {
    // Call the delegate
    delegateQueue.async { [weak self, weak webSocketConnection] in
      guard let self = self, let webSocketConnection = webSocketConnection else { return }
      self.webSocketDelegate?.server(self, webSocket: webSocketConnection, didSendMessage: message)
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didCloseWithError error: Error?) {
    // Remove the websocket connection
    webSocketConnections.remove(webSocketConnection)

    // Call the delegate
    delegateQueue.async { [weak self, weak webSocketConnection] in
      guard let self = self, let webSocketConnection = webSocketConnection else { return }
      self.webSocketDelegate?.server(self, webSocketDidDisconnect: webSocketConnection, error: error)
    }
  }
}
