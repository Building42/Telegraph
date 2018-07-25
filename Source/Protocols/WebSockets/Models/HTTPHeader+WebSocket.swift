//
//  HTTPHeader+WebSocket.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/9/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension CustomKeyIndexable where Key == HTTPHeader, Value == String {
  public var webSocketAccept: String? {
    get { return self["Sec-WebSocket-Accept"] }
    set { self["Sec-WebSocket-Accept"] = newValue }
  }

  public var webSocketKey: String? {
    get { return self["Sec-WebSocket-Key"] }
    set { self["Sec-WebSocket-Key"] = newValue }
  }

  public var webSocketProtocol: String? {
    get { return self["Sec-WebSocket-Protocol"] }
    set { self["Sec-WebSocket-Protocol"] = newValue }
  }

  public var webSocketVersion: String? {
    get { return self["Sec-WebSocket-Version"] }
    set { self["Sec-WebSocket-Version"] = newValue }
  }
}
