//
//  WebSocketClient.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/9/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public protocol WebSocketClientDelegate: class {
  func webSocketClient(_ client: WebSocketClient, didConnectToHost host: String)
  func webSocketClient(_ client: WebSocketClient, didDisconnectWithError error: Error?)

  func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data)
  func webSocketClient(_ client: WebSocketClient, didReceiveText text: String)
}

open class WebSocketClient: WebSocket {
  public let url: URL
  public let host: String
  public let port: Int
  public var headers: HTTPHeaders

  public var config = WebSocketConfig.clientDefault
  public var tlsPolicy: TLSPolicy?
  public weak var delegate: WebSocketClientDelegate?

  private let workQueue = DispatchQueue(label: "Telegraph.WebSocketClient.work")
  private let delegateQueue = DispatchQueue(label: "Telegraph.WebSocketClient.delegate")

  private var httpConnection: HTTPConnection?
  private var webSocketConnection: WebSocketConnection?

  /// Initializes a new WebSocketClient with an url
  public init(url: URL, headers: HTTPHeaders = .empty) throws {
    guard url.hasWebSocketScheme else { throw WebSocketClientError.invalidScheme }
    guard let host = url.host else { throw WebSocketClientError.invalidHost }

    // Store the connection information
    self.url = url
    self.host = host
    self.port = url.port ?? url.portBasedOnScheme
    self.headers = headers

    // Only mask unsecure connections
    config.maskMessages = !url.isSchemeSecure
  }

  /// Performs the handshake with the host, forming the websocket connection.
  public func connect(timeout: TimeInterval = 10) {
    workQueue.async { [weak self] in
      guard let self = self else { return }

      // Release old WebSocket connection if necessary
      self.webSocketConnection = nil

      // Create the socket
      let socket = TCPSocket()
      socket.delegate = self
      socket.tlsPolicy = self.tlsPolicy

      // Create the HTTP connection (retains the socket)
      self.httpConnection = HTTPConnection(socket: socket, config: HTTPConfig.clientDefault)
      self.httpConnection!.delegate = self

      /// Open the socket
      socket.open(toHost: self.host, port: self.port, timeout: timeout)
    }
  }

  /// Disconnects the client. Same as calling close with immediately: true.
  public func disconnect() {
    close(immediately: true)
  }

  /// Closes the connection to the host.
  public func close(immediately: Bool) {
    workQueue.async { [weak self] in
      self?.httpConnection?.close(immediately: immediately)
      self?.webSocketConnection?.close(immediately: immediately)
    }
  }

  /// Sends a raw websocket message.
  public func send(message: WebSocketMessage) {
    workQueue.async { [weak self] in
      self?.webSocketConnection?.send(message: message)
    }
  }

  /// Performs a handshake to initiate the websocket connection.
  private func performHandshake() {
    guard let httpConnection = self.httpConnection else { return }

    // Open the HTTP connection, gives it control over the socket
    httpConnection.open()

    // Create the handshake request
    let requestURI = URI(path: url.path, query: url.query)
    let handshakeRequest = HTTPRequest(uri: requestURI, headers: headers)
    handshakeRequest.webSocketHandshake(host: host, port: port)

    // Perform the handshake request
    httpConnection.send(request: handshakeRequest)
  }

  /// Processes the handshake response.
  private func handleHandshake(response: HTTPResponse) {
    // Validate the handshake response
    guard response.isWebSocketHandshake else {
      let handShakeError = WebSocketClientError.handshakeFailed(response: response)
      handleHandshakeError(handShakeError)
      return
    }

    // Extract the information from the HTTP connection
    guard let (socket, webSocketData) = self.httpConnection?.upgrade() else { return }

    // Release the HTTP connection
    httpConnection = nil

    // Upgrade the connection to a WebSocket connection
    webSocketConnection = WebSocketConnection(socket: socket, config: config)
    webSocketConnection!.delegate = self
    webSocketConnection!.open(data: webSocketData)

    // Inform the delegate that we are connected
    delegateQueue.async { [weak self] in
      guard let self = self else { return }
      self.delegate?.webSocketClient(self, didConnectToHost: self.host)
    }
  }

  /// Handles a connection close.
  private func handleHandshakeError(_ error: Error?) {
    // Prevent any connection delegate calls, we want to provide our own error
    workQueue.async { [weak self] in
      self?.httpConnection?.delegate = nil
      self?.webSocketConnection?.delegate = nil
    }

    // Manually close and report the error
    close(immediately: true)
    handleConnectionClose(error: error)
  }

  /// Handles a connection close.
  private func handleConnectionClose(error: Error?) {
    workQueue.async { [weak self] in
      self?.httpConnection = nil
      self?.webSocketConnection = nil
    }

    delegateQueue.async { [weak self] in
      guard let self = self else { return }
      self.delegate?.webSocketClient(self, didDisconnectWithError: error)
    }
  }
}

// MARK: Convenience initializers

extension WebSocketClient {
  /// Creates a new WebSocketClient with an url in string form.
  public convenience init(_ string: String) throws {
    guard let url = URL(string: string) else { throw WebSocketClientError.invalidURL }
    try self.init(url: url)
  }

  /// Creates a new WebSocketClient with an url in string form and certificates to trust.
  public convenience init(_ string: String, certificates: [Certificate]) throws {
    try self.init(string)
    self.tlsPolicy = TLSPolicy(certificates: certificates)
  }

  /// Creates a new WebSocketClient with an url and certificates to trust.
  public convenience init(url: URL, certificates: [Certificate]) throws {
    try self.init(url: url)
    self.tlsPolicy = TLSPolicy(certificates: certificates)
  }
}

// MARK: TCPSocketDelegate implementation

extension WebSocketClient: TCPSocketDelegate {
  /// Raised when the socket has connected.
  public func socketDidOpen(_ socket: TCPSocket) {
    // Start TLS for secure hosts
    if url.isSchemeSecure {
      socket.startTLS()
    }

    // Send the handshake request
    workQueue.async { [weak self] in self?.performHandshake() }
  }

  /// Raised when the socket disconnected.
  public func socketDidClose(_ socket: TCPSocket, wasOpen: Bool, error: Error?) {
    handleConnectionClose(error: error)
  }
}

// MARK: TCPSocketDelegate implementation

extension WebSocketClient: HTTPConnectionDelegate {
  /// Raised when the HTTPConnecion was closed.
  public func connection(_ httpConnection: HTTPConnection, didCloseWithError error: Error?) {
    handleConnectionClose(error: error)
  }

  /// Raised when the HTTPConnecion received a response.
  public func connection(_ httpConnection: HTTPConnection, handleIncomingResponse response: HTTPResponse, error: Error?) {
    if let error = error {
      handleHandshakeError(error)
      return
    }

    // Process the response on the handshake request
    workQueue.async { [weak self] in
      self?.handleHandshake(response: response)
    }
  }

  /// Raised when the HTTPConnecion received a request (client doesn't support requests -> close).
  public func connection(_ httpConnection: HTTPConnection, handleIncomingRequest request: HTTPRequest, error: Error?) {
    httpConnection.close(immediately: true)
  }

  /// Raised when the HTTPConnecion received a request (client doesn't support request upgrades -> close).
  public func connection(_ httpConnection: HTTPConnection, handleUpgradeByRequest request: HTTPRequest) {
    httpConnection.close(immediately: true)
  }
}

// MARK: WebSocketConnectionDelegate implementation

extension WebSocketClient: WebSocketConnectionDelegate {
  /// Raised when the WebSocketConnection disconnected.
  public func connection(_ webSocketConnection: WebSocketConnection, didCloseWithError error: Error?) {
    handleConnectionClose(error: error)
  }

  /// Raised when the WebSocketConnection receives a message.
  public func connection(_ webSocketConnection: WebSocketConnection, didReceiveMessage message: WebSocketMessage) {
    // We are only interested in binary and text messages
    guard message.opcode == .binaryFrame || message.opcode == .textFrame else { return }

    // Inform the delegate
    delegateQueue.async { [weak self] in
      guard let self = self else { return }
      switch message.payload {
      case let .binary(data): self.delegate?.webSocketClient(self, didReceiveData: data)
      case let .text(text): self.delegate?.webSocketClient(self, didReceiveText: text)
      default: break
      }
    }
  }

  /// Raised when the WebSocketConnection sent a message (ignore).
  public func connection(_ webSocketConnection: WebSocketConnection, didSendMessage message: WebSocketMessage) {}
}
