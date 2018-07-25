//
//  URL+Ext.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/10/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension URL {
  public var hasWebSocketScheme: Bool {
    return scheme == "https" || scheme == "http" || scheme == "wss" || scheme == "ws"
  }

  public var portBasedOnScheme: Int {
    return isSchemeSecure ? 443 : 80
  }

  public var isSchemeSecure: Bool {
    return scheme == "https" || scheme == "wss"
  }
}
