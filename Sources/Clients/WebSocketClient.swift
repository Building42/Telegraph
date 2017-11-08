//
//  WebSocketClient.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/9/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

enum WebSocketClientError: Error {
  case invalidURL
  case invalidScheme
  case invalidHost
  case handshakeFailed(response: HTTPResponse)
}

public protocol WebSocketClientDelegate: class {
  func webSocketClient(_ client: WebSocketClient, didConnectToHost host: String)
  func webSocketClient(_ client: WebSocketClient, didDisconnectWithError error: Error?)

  func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data)
  func webSocketClient(_ client: WebSocketClient, didReceiveText text: String)
}

open class WebSocketClient: WebSocket {
  private let workQueue = DispatchQueue(label: "Telegraph.WebSocketClient.work")
  private let delegateQueue = DispatchQueue(label: "Telegraph.WebSocketClient.delegate")
  private var httpClient: HTTPClient?
  private var connection: WebSocketConnection?

  public let url: URL
  public var headers = HTTPHeaders()
  public var config: WebSocketConfig = WebSocketConfig.clientDefault
  public var tlsPolicy: TLSPolicy?
  public weak var delegate: WebSocketClientDelegate?

  /// Initializes a new WebSocketClient with an url
  public init(url: URL) throws {
    guard url.hasWebSocketScheme else { throw WebSocketClientError.invalidScheme }
    guard url.host != nil else { throw WebSocketClientError.invalidHost }
    self.url = url

    // Only mask unsecure connections
    config.maskMessages = !url.isSchemeSecure
  }

  /// Performs the handshake with the host, forming the websocket connection.
  public func connect(timeout: TimeInterval = 10) {
    workQueue.async(weak: self) { me in
      guard me.httpClient == nil && me.connection == nil else { return }
      me.performHandshake(timeout: timeout)
    }
  }

  /// Disconnects the client. Same as calling close with immediately: true.
  public func disconnect() {
    close(immediately: true)
  }

  /// Closes the connection to the host.
  public func close(immediately: Bool) {
    workQueue.async(weak: self) { me in
      me.connection?.close(immediately: immediately)
    }
  }

  /// Sends a raw websocket message.
  public func send(message: WebSocketMessage) {
    workQueue.async(weak: self) { me in
      me.connection?.send(message: message)
    }
  }

  /// Performs a handshake to initiate the websocket connection.
  private func performHandshake(timeout: TimeInterval) {
    // Create the handshake request
    let handshakeRequest = HTTPRequest()
    handshakeRequest.webSocketHandshake(host: url.host!, port: url.port ?? url.portBasedOnScheme)

    // Apply the custom headers
    for header in headers {
      handshakeRequest.headers[header.key] = header.value
    }

    // Set the URI on the request
    if let uri = URI(url: url) {
      handshakeRequest.uri = uri
    }

    // Create the HTTP client
    httpClient = HTTPClient(baseURL: url)
    httpClient!.connectTimeout = timeout
    httpClient!.tlsPolicy = tlsPolicy

    // Perform the handshake request
    httpClient!.request(handshakeRequest) { [weak self] response, error in
      self?.workQueue.async { self?.handleHandshake(response: response, error: error) }
    }
  }

  /// Processes the handshake response.
  private func handleHandshake(response: HTTPResponse, error: Error?) {
    // Clean up http client to allow another connect after the connection closes
    let socket = httpClient!.socket
    httpClient = nil

    if error == nil && response.isWebSocketHandshake {
      // Upgrade the connection to a websocket connection
      connection = WebSocketConnection(socket: socket, config: config)
      connection!.delegate = self
      connection!.open()

      // Inform the delegate that we are connected
      delegateQueue.async(weak: self) { me in me.delegate?.webSocketClient(me, didConnectToHost: me.url.host!) }
    } else {
      // Inform the delegate of the handshake error
      let handshakeError = error ?? WebSocketClientError.handshakeFailed(response: response)
      delegateQueue.async(weak: self) { me in me.delegate?.webSocketClient(me, didDisconnectWithError: handshakeError) }
    }
  }
}

// MARK: Convenience initializers

extension WebSocketClient {
  /// Initializes a new WebSocketClient with an url in string form.
  public convenience init(_ string: String) throws {
    guard let url = URL(string: string) else { throw WebSocketClientError.invalidURL }
    try self.init(url: url)
  }

  /// Initializes a new WebSocketClient with an url in string form and certificates to trust.
  public convenience init(_ string: String, certificates: [Certificate]) throws {
    try self.init(string)
    self.tlsPolicy = TLSPolicy(certificates: certificates)
  }

  /// Initializes a new WebSocketClient with an url and certificates to trust.
  public convenience init(url: URL, certificates: [Certificate]) throws {
    try self.init(url: url)
    self.tlsPolicy = TLSPolicy(certificates: certificates)
  }
}

// MARK: WebSocketConnectionDelegate implementation

extension WebSocketClient: WebSocketConnectionDelegate {
  public func connection(_ webSocketConnection: WebSocketConnection, didCloseWithError error: Error?) {
    workQueue.async(weak: self) { me in
      guard me.connection == webSocketConnection else { return }
      me.connection?.delegate = nil
      me.connection = nil
    }

    delegateQueue.async(weak: self) { me in me.delegate?.webSocketClient(me, didDisconnectWithError: error) }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didReceiveMessage message: WebSocketMessage) {
    // We are only interested in binary and text messages
    guard message.opcode == .binaryFrame || message.opcode == .textFrame else { return }

    // Inform the delegate
    switch message.payload {
    case let .binary(data): delegateQueue.async(weak: self) { me in me.delegate?.webSocketClient(me, didReceiveData: data) }
    case let .text(text): delegateQueue.async(weak: self) { me in me.delegate?.webSocketClient(me, didReceiveText: text) }
    default: break
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didSendMessage message: WebSocketMessage) {}
}
