//
//  HTTPResponse.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/31/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

open class HTTPResponse: HTTPMessage {
  public typealias Handler = (HTTPResponse, Error) -> Void
  public static let dateFormatter = DateFormatter.rfc7231

  public var status: HTTPStatus
  public var closeAfterWrite = false

  /// Initializes a new HTTPResponse
  public init(_ statusCode: HTTPStatusCode = .ok) {
    self.status = HTTPStatus(code: statusCode)
    super.init()
  }

  /// Writes the first line of the response, e.g. HTTP/1.1 200 OK
  override internal var firstLine: String {
    return "\(version) \(status.code) \(status.phrase)"
  }

  /// Prepares the response to be written tot the stream
  override open func prepareForWrite() {
    super.prepareForWrite()

    // Set the date header
    headers.date = HTTPResponse.dateFormatter.string(from: Date())

    // If a body is allowed set the content length (even when 0)
    if status.supportsBody {
      headers.contentLength = body.count
    } else {
      headers.contentLength = nil
      body = Data()
    }
  }
}

// MARK: Convenience initializers

extension HTTPResponse {
  public convenience init(_ statusCode: HTTPStatusCode = .ok, data: Data) {
    self.init(statusCode)
    body = data
  }

  public convenience init(_ statusCode: HTTPStatusCode = .ok, content: String) {
    self.init(statusCode, data: content.utf8Data)
  }

  public convenience init(_ statusCode: HTTPStatusCode = .internalServerError, error: Error) {
    self.init(statusCode, content: "\(error)")
    self.closeAfterWrite = true
  }
}

// MARK: CustomStringConvertible

extension HTTPResponse: CustomStringConvertible {
  open var description: String {
    var info = ""
    var msg = self

    withUnsafePointer(to: &msg) {
      info += "<\(type(of: msg)): \($0)"
      info += " status: \(msg.status),"
      info += " headers: \(msg.headers.count),"
      info += " body: \(msg.body.count)>"
    }

    return info
  }
}
