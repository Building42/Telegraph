//
//  HTTPMessage.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/30/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

open class HTTPMessage {
  public var headers = HTTPHeaders()
  public var body = Data()
  public var version = HTTPVersion(1, 1)

  internal var firstLine: String { return "" }

  open func prepareForWrite() {
    // Set the keep alive connection header
    if version.minor == 0 {
      keepAlive = false
    } else if headers.connection == nil {
      keepAlive = true
    }
  }
}

// MARK: Helper methods

extension HTTPMessage {
  var keepAlive: Bool {
    get { return headers.connection?.lowercased() != "close" }
    set { headers.connection = newValue ? "keep-alive" : "close" }
  }

  var isConnectionUpgrade: Bool {
    get { return headers.connection?.lowercased() == "upgrade" }
    set { headers.connection = newValue ? "upgrade" : nil }
  }
}
