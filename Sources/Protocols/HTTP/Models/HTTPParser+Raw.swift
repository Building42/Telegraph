//
//  HTTPParser+Raw.swift
//  Telegraph
//
//  Created by Yvo van Beek on 10/12/18.
//  Copyright © 2018 Building42. All rights reserved.
//

import HTTPParserC

// MARK: Types

typealias HTTPRawParser = llhttp_t
typealias HTTPRawParserSettings = llhttp_settings_t
typealias HTTPRawParserErrorCode = llhttp_errno
typealias HTTPRawMethod = llhttp_method_t
typealias ChunkPointer = UnsafePointer<Int8>

// MARK: HTTPRawParser

extension HTTPRawParser {
  /// Creates a new HTTPRawParser.
  static func make() -> HTTPRawParser {
    return HTTPRawParser()
  }

  /// Completes the initialization steps of the parser.
  static func prepare(parser: UnsafeMutablePointer<HTTPRawParser>, settings: UnsafeMutablePointer<HTTPRawParserSettings>) {
    llhttp_init(parser, LLHTTP_BOTH, settings)
  }

  /// Parses the incoming data and returns an optional error.
  static func parse(parser: UnsafeMutablePointer<HTTPRawParser>, data: Data) -> Bool {
    return data.withUnsafeBytes {
      let pointer = $0.bindMemory(to: Int8.self).baseAddress
      var resultCode = llhttp_execute(parser, pointer, data.count)

      // No need to pause after upgrade requests
      if resultCode == HPE_PAUSED_UPGRADE {
        llhttp_resume_after_upgrade(parser)
        resultCode = HPE_OK
      }

      return resultCode == HPE_OK
    }
  }

  /// Resets the parser.
  static func reset(parser: UnsafeMutablePointer<HTTPRawParser>) {
    llhttp_reset(parser)
  }

  /// Returns the context.
  func context<T: AnyObject>() -> T {
    return Unmanaged<T>.fromOpaque(data).takeUnretainedValue()
  }

  /// Sets the context.
  mutating func setContext<T: AnyObject>(_ context: T) {
    data = Unmanaged.passUnretained(context).toOpaque()
  }
}

extension HTTPRawParser {
  /// Returns the content length header.
  var contentLength: Int {
    return content_length > Int.max ? 0 : Int(content_length)
  }

  /// Returns the error that occurred during parsing.
  var httpError: HTTPError? {
    return HTTPError(rawCode: error)
  }

  /// Returns the HTTP method.
  var httpMethod: HTTPMethod {
    let methodCode = HTTPRawMethod(UInt32(method))
    let methodName = String(cString: llhttp_method_name(methodCode))
    return HTTPMethod(name: methodName)
  }

  /// Returns the HTTP status.
  var httpStatusCode: Int {
    return Int(status_code)
  }

  /// Returns the HTTP version.
  var httpVersion: HTTPVersion {
    return HTTPVersion(major: UInt(http_major), minor: UInt(http_minor))
  }

  /// Returns a boolean indicating if the parser is ready to parse.
  var isReady: Bool {
    return error == HPE_OK.rawValue
  }

  /// Returns a boolean indicating if the parser detected a connection upgrade.
  var isUpgradeDetected: Bool {
    return upgrade == 1
  }
}

// MARK: HTTPRawParserSettings

extension HTTPRawParserSettings {
  /// Creates a new HTTPRawParserSettings.
  static func make() -> HTTPRawParserSettings {
    var settings = HTTPRawParserSettings()
    llhttp_settings_init(&settings)
    return settings
  }
}

// MARK: RawParserErrorCode to HTTPError mapping

extension HTTPError {
  init?(code: HTTPRawParserErrorCode) {
    if code == HPE_OK { return nil }

    switch code {
    case HPE_INVALID_EOF_STATE:
      self = .unexpectedStreamEnd
    case HPE_CLOSED_CONNECTION:
      self = .connectionShouldBeClosed
    case HPE_INVALID_VERSION:
      self = .invalidVersion
    case HPE_INVALID_METHOD:
      self = .invalidMethod
    case HPE_INVALID_URL:
      self = .invalidURI
    case HPE_INVALID_HEADER_TOKEN:
      self = .invalidHeader
    case HPE_INVALID_CONTENT_LENGTH:
      self = .invalidContentLength
    default:
      self = .parseFailed(code: Int(code.rawValue))
    }
  }

  init?(rawCode: Int32) {
    let errorCode = HTTPRawParserErrorCode(UInt32(rawCode))
    guard let error = HTTPError(code: errorCode) else { return nil }
    self = error
  }
}
