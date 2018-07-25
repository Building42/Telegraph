//
//  HTTPMessage+WebSocket.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/16/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension HTTPMessage {
  public static let webSocketProtocol = "websocket"
  public static let webSocketVersion = "13"
  fileprivate static let webSocketMagicGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  var isWebSocketUpgrade: Bool {
    get { return headers.upgrade?.lowercased() == HTTPMessage.webSocketProtocol }
    set { headers.upgrade = newValue ? HTTPMessage.webSocketProtocol : nil }
  }
}

extension HTTPRequest {
  /// Creates a websocket handshake request.
  static func webSocketHandshake(host: String, port: Int = 80) -> HTTPRequest {
    let request = HTTPRequest()
    request.webSocketHandshake(host: host, port: port)
    return request
  }

  /// Decorates a request with websocket handshake headers.
  func webSocketHandshake(host: String, port: Int = 80) {
    method = .get
    setHostHeader(host: host, port: port)

    isConnectionUpgrade = true
    isWebSocketUpgrade = true

    headers.webSocketProtocol = ""
    headers.webSocketVersion = HTTPMessage.webSocketVersion
    headers.webSocketKey = Data(randomNumberOfBytes: 16).base64EncodedString()
  }
}

extension HTTPResponse {
  /// Creates a websocket handshake response.
  static func webSocketHandshake(key: String) -> HTTPResponse {
    let response = HTTPResponse()
    response.webSocketHandshake(key: key)
    return response
  }

  /// Decorates a response with websocket handshake headers.
  func webSocketHandshake(key: String) {
    status = HTTPStatus(code: .switchingProtocols)

    isConnectionUpgrade = true
    isWebSocketUpgrade = true

    // Take the incoming key, append the static GUID and return a base64 encoded SHA-1 hash
    let sha1 = SHA1(string: key.appending(HTTPMessage.webSocketMagicGUID))
    headers.webSocketAccept = sha1.data.base64EncodedString()
  }

  // Indicates if the response contains a supported websocket handshake
  var isWebSocketHandshake: Bool {
    return
      isWebSocketUpgrade &&
      status == .switchingProtocols &&
      headers.webSocketAccept?.isEmpty == false
  }
}
