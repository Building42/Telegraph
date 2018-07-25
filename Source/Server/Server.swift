//
//  Server.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/20/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

open class Server {
  public var delegateQueue: DispatchQueue = DispatchQueue(label: "Telegraph.Server.delegate")

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
      guard let strongSelf = self else { return }
      strongSelf.webSocketDelegate?.serverDidDisconnect(strongSelf)
    }
  }
}

// MARK: HTTPConnectionDelegate implementation

extension Server: HTTPConnectionDelegate {
  /// Raised when a HTTP connection receives an incoming request.
  public func connection(_ httpConnection: HTTPConnection, handleIncomingRequest request: HTTPRequest, error: Error?) -> HTTPResponse? {
    do {
      // Let the HTTP chain handle the request
      if let error = error { throw error }
      return try httpConfig.requestChain(request)
    } catch {
      // Or pass it to the error handler if something is wrong
      return httpConfig.errorHandler.respond(to: error)
    }
  }

  /// Raised when a HTTP connection requests an connection upgrade.
  public func connection(_ httpConnection: HTTPConnection, handleUpgradeTo protocolName: String, initiatedBy request: HTTPRequest) -> Bool {
    // We can only handle the WebSocket protocol
    guard protocolName == HTTPMessage.webSocketProtocol else { return false }

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
      guard let strongSelf = self, let webSocketConnection = webSocketConnection else { return }
      strongSelf.webSocketDelegate?.server(strongSelf, webSocketDidConnect: webSocketConnection, handshake: request)
    }

    return true
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
      guard let strongSelf = self, let webSocketConnection = webSocketConnection else { return }
      strongSelf.webSocketDelegate?.server(strongSelf, webSocket: webSocketConnection, didReceiveMessage: message)
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didSendMessage message: WebSocketMessage) {
    // Call the delegate
    delegateQueue.async { [weak self, weak webSocketConnection] in
      guard let strongSelf = self, let webSocketConnection = webSocketConnection else { return }
      strongSelf.webSocketDelegate?.server(strongSelf, webSocket: webSocketConnection, didSendMessage: message)
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didCloseWithError error: Error?) {
    // Remove the websocket connection
    webSocketConnections.remove(webSocketConnection)

    // Call the delegate
    delegateQueue.async { [weak self, weak webSocketConnection] in
      guard let strongSelf = self, let webSocketConnection = webSocketConnection else { return }
      strongSelf.webSocketDelegate?.server(strongSelf, webSocketDidDisconnect: webSocketConnection, error: error)
    }
  }
}
