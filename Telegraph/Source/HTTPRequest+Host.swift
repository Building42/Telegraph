//
//  HTTPRequest+Host.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/20/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension HTTPRequest {
  /// Initializes the request with a method, url and sets the host header.
  public convenience init?(_ method: HTTPMethod, url: URL, headers: HTTPHeaders = [:]) {
    guard let uri = URI(url: url) else { return nil }
    self.init(method, uri: uri, headers: headers)

    setHostHeader(host: url.host, port: url.port)
  }

  // Sets the host header to the specified host and port.
  public func setHostHeader(host: String?, port: Int? = nil) {
    var value: String?

    if let host = host {
      value = "\(host)"

      // The default port is 80, no need to send that
      if let port = port, port != 80 {
        value?.append(":\(port)")
      }
    }

    headers.host = value
  }
}
