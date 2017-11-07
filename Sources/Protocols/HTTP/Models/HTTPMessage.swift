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
  internal var stripBody = false

  /// Performs last minute changes to the message, just before writing it to the stream.
  open func prepareForWrite() {
    // Set the keep alive connection header
    if version.minor == 0 {
      keepAlive = false
    } else if headers.connection == nil {
      keepAlive = true
    }
  }

  /// Writes the HTTP message to the provided stream.
  public func write(to stream: WriteStream, headerTimeout: TimeInterval, bodyTimeout: TimeInterval) {
    writeHeader(to: stream, timeout: headerTimeout)
    writeBody(to: stream, timeout: bodyTimeout)
    stream.flush()
  }

  /// Writes the first line and headers to the provided stream.
  open func writeHeader(to stream: WriteStream, timeout: TimeInterval) {
    // Write the first line
    stream.write(data: firstLine.utf8Data, timeout: timeout)
    stream.write(data: .crlf, timeout: timeout)

    // Write the headers
    headers.forEach { key, value in
      stream.write(data: "\(key): \(value)".utf8Data, timeout: timeout)
      stream.write(data: .crlf, timeout: timeout)
    }

    // Signal the end of the headers with another crlf
    stream.write(data: .crlf, timeout: timeout)
  }

  /// Writes the body to the provided stream.
  open func writeBody(to stream: WriteStream, timeout: TimeInterval) {
    if !stripBody {
      stream.write(data: body, timeout: timeout)
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
