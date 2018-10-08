//
//  HTTPHeader+WebSocket.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/9/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension HTTPHeaderName {
  static let webSocketAccept = HTTPHeaderName("sec-websocket-accept")
  static let webSocketKey = HTTPHeaderName("sec-websocket-key")
  static let webSocketProtocol = HTTPHeaderName("sec-websocket-protocol")
  static let webSocketVersion = HTTPHeaderName("sec-websocket-version")
}

extension Dictionary where Key == HTTPHeaderName, Value == String {
  public var webSocketAccept: String? {
    get { return self[.webSocketAccept] }
    set { self[.webSocketAccept] = newValue }
  }

  public var webSocketKey: String? {
    get { return self[.webSocketKey] }
    set { self[.webSocketKey] = newValue }
  }

  public var webSocketProtocol: String? {
    get { return self[.webSocketProtocol] }
    set { self[.webSocketProtocol] = newValue }
  }

  public var webSocketVersion: String? {
    get { return self[.webSocketVersion] }
    set { self[.webSocketVersion] = newValue }
  }
}
