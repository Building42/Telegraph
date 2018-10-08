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
    method = .GET
    setHostHeader(host: host, port: port)

    isConnectionUpgrade = true
    isWebSocketUpgrade = true

    headers.webSocketProtocol = ""
    headers.webSocketVersion = HTTPMessage.webSocketVersion
    headers.webSocketKey = Data(randomNumberOfBytes: 16).base64EncodedString()
  }
}

public extension HTTPResponse {
  /// Creates a websocket handshake response.
  static func webSocketHandshake(key: String) -> HTTPResponse {
    // Take the incoming key, append the static GUID and return a base64 encoded SHA-1 hash
    let webSocketKey = key.appending(HTTPMessage.webSocketMagicGUID)
    let webSocketAccept = SHA1.hash(webSocketKey).base64EncodedString()

    let response = HTTPResponse(.switchingProtocols)
    response.isConnectionUpgrade = true
    response.isWebSocketUpgrade = true
    response.headers.webSocketAccept = webSocketAccept
    return response
  }

  // Returns a boolean indicating if the response is a websocket handshake.
  var isWebSocketHandshake: Bool {
    return status == .switchingProtocols && isWebSocketUpgrade &&
      headers.webSocketAccept?.isEmpty == false
  }
}
