//
//  HTTPRequest.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/31/17.
//  Copyright © 2017 Building42. All rights reserved.
//

open class HTTPRequest: HTTPMessage {
  public typealias Params = [String: String]

  public var method: HTTPMethod
  public var uri: URI
  public var params: Params = Params()

  public init(_ method: HTTPMethod = .get, uri: URI = URI()) {
    self.method = method
    self.uri = uri
    super.init()
  }

  override internal var firstLine: String {
    // The first line looks like this: GET / HTTP/1.1
    return "\(method) \(uri) \(version)"
  }

  override open func prepareForWrite() {
    super.prepareForWrite()

    // Write the content length only if we have a body
    headers.contentLength = body.isEmpty ? nil : body.count
  }
}

// MARK: Convenience initializers

extension HTTPRequest {
  public convenience init(_ method: HTTPMethod, uri: URI, headers: HTTPHeaders = [:]) {
    self.init(method, uri: uri)
    self.headers = headers
  }
}

// MARK: CustomStringConvertible implementation

extension HTTPRequest: CustomStringConvertible {
  open var description: String {
    var info = ""
    var msg = self

    withUnsafePointer(to: &msg) {
      info += "<\(type(of: msg)): \($0)"
      info += " method: \(msg.method),"
      info += " uri: \(msg.uri),"
      info += " headers: \(msg.headers.count),"
      info += " body: \(msg.body.count)>"
    }

    return info
  }
}
