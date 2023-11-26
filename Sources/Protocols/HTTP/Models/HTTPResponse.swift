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

  public var status: HTTPStatus

  internal let isComplete: Bool

  /// Initializes a new HTTPResponse
  public init(_ status: HTTPStatus = .ok, version: HTTPVersion = .default,
              headers: HTTPHeaders = .empty, body: Data = Data(), isComplete: Bool = true) {
    self.status = status
    self.isComplete = isComplete
    super.init(version: version, headers: headers, body: body)
  }

  /// Writes the first line of the response, e.g. HTTP/1.1 200 OK
  override internal var firstLine: String {
    return "\(version) \(status)"
  }

  /// Prepares the response to be written tot the stream
  override open func prepareForWrite() {
    super.prepareForWrite()

    // Set the date header
    headers.date = Date().rfc1123

    // A reponse might be followed by more data
    if isComplete {
      // If a body is allowed set the content length (even when 0)
      if status.supportsBody {
        headers.contentLength = body.count
      } else {
        headers.contentLength = nil
        body.count = 0
      }
    }
  }
}

// MARK: Convenience initializers

public extension HTTPResponse {
  /// Creates an HTTP response to send textual content.
  convenience init(_ status: HTTPStatus = .ok, headers: HTTPHeaders = .empty, content: String) {
    self.init(status, headers: headers, body: content.utf8Data)
  }
    
    /// Creates an HTTP response to send codable content
    /// Sends a 501 if there is an error encoding the data
    /// - Parameters:
    ///   - encodable: Encodable data to send to the client
    ///   - encoder: Default assumption is that you are encoding as JSON, and the contentType header is set by default to reflect this. 
    convenience init(_ status: HTTPStatus = .ok,version: HTTPVersion = .default,headers: HTTPHeaders = [.contentType:"application/json"],encodable: Codable,encoder:JSONEncoder = JSONEncoder(),isComplete: Bool = true) {
        do {
            let data = try encoder.encode(encodable)
            self.init(
                status,
                version: version,
                headers: headers,
                body: data,
                isComplete: isComplete
            )
        } catch  {
            self.init(.internalServerError, content: "501: Internal server error")
        }
        
    }

  /// Creates an HTTP response to send an error.
  convenience init(_ status: HTTPStatus = .internalServerError, headers: HTTPHeaders = .empty, error: Error) {
    var errorHeaders = headers
    errorHeaders.connection = "close"

    self.init(status, headers: errorHeaders, body: error.localizedDescription.utf8Data)
  }
}

// MARK: CustomStringConvertible

extension HTTPResponse: CustomStringConvertible {
  public var description: String {
    let typeName = type(of: self)
    return "<\(typeName): \(version) \(status), headers: \(headers.count), body: \(body.count)>"
  }
}
