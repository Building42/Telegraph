//
//  HTTPWebSocketHandler.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/19/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

open class HTTPWebSocketHandler: HTTPRequestHandler {
  open func respond(to request: HTTPRequest, nextHandler: HTTPRequest.Handler) throws -> HTTPResponse? {
    // Skip if this isn't a websocket upgrade request
    guard request.isWebSocketUpgrade else {
      return try nextHandler(request)
    }

    // Validate the handshake
    guard request.method == .get else { throw HTTPError.invalidMethod }
    guard request.version.minor == 1 else { throw HTTPError.invalidVersion }

    // We must have a websocket key
    guard let webSocketKey = request.headers.webSocketKey else {
      return HTTPResponse(.badRequest, content: "Websocket key is missing")
    }

    // Check that we support the websocket version
    guard request.headers.webSocketVersion == HTTPMessage.webSocketVersion else {
      return HTTPResponse(.notImplemented, content: "Websocket version not supported")
    }

    return .webSocketHandshake(key: webSocketKey)
  }
}
