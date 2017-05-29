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
  fileprivate var httpClient: HTTPClient?
  fileprivate var connection: WebSocketConnection?

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
    guard httpClient == nil && connection == nil else { return }

    // Create the handshake request
    let handshakeRequest = HTTPRequest()
    handshakeRequest.headers = headers
    handshakeRequest.webSocketHandshake(host: url.host!, port: url.port ?? url.portBasedOnScheme)

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
      self?.handleHandshake(response: response, error: error)
    }
  }

  /// Disconnects the client. Same as calling close with immediately: true.
  public func disconnect() {
    close(immediately: true)
  }

  /// Closes the connection to the host.
  public func close(immediately: Bool) {
    connection?.close(immediately: immediately)
  }

  /// Sends a raw websocket message.
  public func send(message: WebSocketMessage) {
    connection?.send(message: message)
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
      delegate?.webSocketClient(self, didConnectToHost: url.host!)
    } else {
      // Inform the delegate of the handshake error
      let handshakeError = error ?? WebSocketClientError.handshakeFailed(response: response)
      delegate?.webSocketClient(self, didDisconnectWithError: handshakeError)
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
    connection?.delegate = nil
    connection = nil

    delegate?.webSocketClient(self, didDisconnectWithError: error)
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didReceiveMessage message: WebSocketMessage) {
    // We are only interested in binary and text messages
    guard message.opcode == .binaryFrame || message.opcode == .textFrame else { return }

    // Inform the delegate
    switch message.payload {
    case let .binary(data): delegate?.webSocketClient(self, didReceiveData: data)
    case let .text(text): delegate?.webSocketClient(self, didReceiveText: text)
    default: break
    }
  }

  public func connection(_ webSocketConnection: WebSocketConnection, didSendMessage message: WebSocketMessage) {}
}
