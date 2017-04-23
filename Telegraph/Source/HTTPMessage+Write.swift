//
//  HTTPMessage+Write.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/20/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension HTTPMessage {
  open func writeTo(stream: WriteStream, headerTimeout: TimeInterval, bodyTimeout: TimeInterval) {
    prepareForWrite()

    // Write the first line
    stream.write(data: firstLine.utf8Data, timeout: headerTimeout)
    stream.write(data: .crlf, timeout: headerTimeout)

    // Write the headers
    headers.forEach { key, value in
      stream.write(data: "\(key): \(value)".utf8Data, timeout: headerTimeout)
      stream.write(data: .crlf, timeout: headerTimeout)
    }

    // Signal the end of the headers with another crlf
    stream.write(data: .crlf, timeout: headerTimeout)

    // Write the body
    stream.write(data: body, timeout: bodyTimeout)

    stream.flush()
  }
}
