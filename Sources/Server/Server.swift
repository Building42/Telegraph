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

  private let workQueue = DispatchQueue(label: "Telegraph.Server.work")
  private var listener: TCPListener
  private var httpConnections = Set<HTTPConnection>()
  private var webSocketConnections = Set<WebSocketConnection>()

  /// Initializes a new Server instance.
  public init() {
    listener = TCPListener(tlsConfig: nil)
    listener.delegate = self
  }

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
    workQueue.sync {
      httpConnections.forEach { $0.close(immediately: immediately) }
      webSocketConnections.forEach { $0.close(immediately: immediately) }
    }
  }

  /// Returns the port on which the listener is accepting connections.
  open var port: UInt16 {
    return listener.port
  }

  /// Handles an incoming HTTP request.
  private func handle(request: HTTPRequest, error: Error?) -> HTTPResponse? {
    do {
      if let error = error { throw error }
      return try httpConfig.requestChain(request)
    } catch {
      return httpConfig.errorHandler.respond(to: error)
    }
  }
}

// MARK: Server properties

extension Server {
  /// Returns a boolean indicating if the server is secure (HTTPS).
  public var isSecure: Bool {
    return listener.tlsConfig == nil
  }

  /// Returns the number of active HTTP connections.
  public var httpConnectionCount: Int {
    return workQueue.sync { httpConnections.count }
  }

  /// Returns the number of active WebSocket connections.
  public var webSocketCount: Int {
    return workQueue.sync { webSocketConnections.count }
  }

  /// Returns the connected
  public var webSockets: [WebSocket] {
    return workQueue.sync { Array(webSocketConnections) as [WebSocket] }
  }
}

// MARK: TCPListenerDelegate implementation

extension Server: TCPListenerDelegate {
  public func listener(_ listener: TCPListener, didAcceptSocket socket: TCPSocket) {
    workQueue.async(weak: self) { me in
      // Wrap the socket in a connection
      let httpConnection = HTTPConnection(socket: socket, config: me.httpConfig)
      me.httpConnections.insert(httpConnection)

      // Open the http connection
      httpConnection.delegate = me
      httpConnection.open()
    }
  }
}

// MARK: HTTPConnectionDelegate implementation

extension Server: HTTPConnectionDelegate {
  public func connection(_ httpConnection: HTTPConnection, didCloseWithError error: Error?) {
    workQueue.async(weak: self) { me in
      me.httpConnections.remove(httpConnection)
    }
  }

  public func connection(_ httpConnection: HTTPConnection, handleIncomingRequest request: HTTPRequest, error: Error?) -> HTTPResponse? {
    return handle(request: request, error: error)
  }

  public func connection(_ httpConnection: HTTPConnection, handleUpgradeTo protocolName: String, initiatedBy request: HTTPRequest) -> Bool {
    // We can only handle the WebSocket protocol
    guard protocolName == HTTPMessage.webSocketProtocol else { return false }

    workQueue.async(weak: self) { me in
      // Remove the http connection
      me.httpConnections.remove(httpConnection)

      // Add the websocket connection
      let webSocketConnection = WebSocketConnection(socket: httpConnection.socket, config: me.webSocketConfig)
      me.webSocketConnections.insert(webSocketConnection)

      // Open the websocket connection
      webSocketConnection.delegate = me
      webSocketConnection.open()

      // Call the delegate
      me.delegateQueue.async(weak: me) { server in
        server.webSocketDelegate?.server(server, webSocketDidConnect: webSocketConnection, handshake: request)
      }
    }

    return true
  }
}

// MARK: WebSocketConnectionDelegate implementation

extension Server: WebSocketConnectionDelegate {
  public func connection(_ webSocketConnection: WebSocketConnection, didCloseWithError error: Error?) {
    workQueue.async(weak: self) { me in
      // Remove the websocket connection
      me.webSocketConnections.remove(webSocketConnection)

      // Call the delegate
      me.delegateQueue.async(weak: me) { server in
        server.webSocketDelegate?.server(server, webSocketDidDisconnect: webSocketConnection, error: error)
      }
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didReceiveMessage message: WebSocketMessage) {
    // Call the delegate
    delegateQueue.async(weak: self) { server in
      server.webSocketDelegate?.server(server, webSocket: webSocketConnection, didReceiveMessage: message)
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didSendMessage message: WebSocketMessage) {
    // Call the delegate
    delegateQueue.async(weak: self) { server in
      server.webSocketDelegate?.server(server, webSocket: webSocketConnection, didSendMessage: message)
    }
  }
}
