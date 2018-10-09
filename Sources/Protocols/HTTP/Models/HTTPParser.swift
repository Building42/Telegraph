//
//  HTTPParser.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/31/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation
import HTTPParserC

// MARK: Constants / Types

private let continueParsing: Int32 = 0
private let stopParsing: Int32 = -1

private typealias RawParser = http_parser
private typealias RawParserErrorCode = http_errno
private typealias RawParserSettings = http_parser_settings
private typealias RawParserPointer = UnsafeMutablePointer<RawParser>
private typealias RawChunkPointer = UnsafePointer<Int8>

// MARK: HTTPParserDelegate

public protocol HTTPParserDelegate: class {
  func parser(_ parser: HTTPParser, didParseHeadersOfMessage message: HTTPMessage)
  func parser(_ parser: HTTPParser, didCompleteMessage message: HTTPMessage)
}

// MARK: HTTPParser

public final class HTTPParser {
  public weak var delegate: HTTPParserDelegate?

  public private(set) var message: HTTPMessage?
  private var request: HTTPRequest? { return message as? HTTPRequest }
  private var response: HTTPResponse? { return message as? HTTPResponse }

  private var rawParser: RawParser
  private var rawParserSettings: RawParserSettings

  private var urlData = Data()
  private var statusData = Data()
  private var headerKeyData = Data()
  private var headerValueData = Data()
  private var headerChunkWasValue = false

  /// Creates an HTTP parser.
  public init() {
    // Prepares the raw parser and settings
    rawParser = RawParser.create()
    rawParserSettings = RawParser.createSettings()

    /// Provide the callback for when the parser is starting a new message.
    rawParserSettings.on_message_begin = { rawParserPointer in
      guard let rawParser = rawParserPointer?.pointee else { return stopParsing }
      return rawParser.parser.messageBegin(rawParser: rawParser)
    }

    // Provide the callback for when the parser is parsing chunks of the URL.
    rawParserSettings.on_url = { rawParserPointer, chunk, count in
      guard let rawParser = rawParserPointer?.pointee else { return stopParsing }
      return rawParser.parser.parsedURL(rawParser: rawParser, chunk: chunk, count: count)
    }

    // Provide the callback for when the parser is parsing chunks of the HTTP status.
    rawParserSettings.on_status = { rawParserPointer, chunk, count in
      guard let rawParser = rawParserPointer?.pointee else { return stopParsing }
      return rawParser.parser.parsedStatus(rawParser: rawParser, chunk: chunk, count: count)
    }

    // Provide the callback for when the parser is parsing chunks of the header key.
    rawParserSettings.on_header_field = { rawParserPointer, chunk, count in
      guard let rawParser = rawParserPointer?.pointee else { return stopParsing }
      return rawParser.parser.parsedHeaderKey(chunk: chunk, count: count)
    }

    // Provide the callback for when the parser is parsing chunks of the header key.
    rawParserSettings.on_header_value = { rawParserPointer, chunk, count in
      guard let rawParser = rawParserPointer?.pointee else { return stopParsing }
      return rawParser.parser.parsedHeaderValue(chunk: chunk, count: count)
    }

    // Provide the callback for when the parser is done parsing the headers.
    rawParserSettings.on_headers_complete = { rawParserPointer in
      guard let rawParser = rawParserPointer?.pointee else { return stopParsing }
      return rawParser.parser.headersComplete(rawParser: rawParser)
    }

    // Provide the callback for when the parser is parsing chunks of the body.
    rawParserSettings.on_body = { rawParserPointer, chunk, count in
      guard let rawParser = rawParserPointer?.pointee else { return stopParsing }
      return rawParser.parser.parsedBody(chunk: chunk, count: count)
    }

    /// Provide the callback for when the parser is done parsing a whole message.
    rawParserSettings.on_message_complete = { rawParserPointer in
      guard let rawParser = rawParserPointer?.pointee else { return stopParsing }
      return rawParser.parser.messageComplete(rawParser: rawParser)
    }

    // Assign ourself as target for the callbacks
    rawParser.parser = self
  }

  /// Parses the incoming data and returns how many bytes were parsed.
  @discardableResult public func parse(data: Data) throws -> Int {
    // Check if the parser is ready, it might need a reset because of previous errors
    if !rawParser.isReady {
      rawParser.reset()
    }

    // Parse the provided data
    let bytesParsed = data.withUnsafeBytes {
      http_parser_execute(&rawParser, &rawParserSettings, $0, data.count)
    }

    // Was there an error?
    if let error = rawParser.httpError {
      cleanup()
      throw error
    }

    return bytesParsed
  }

  /// Clears the helper variables.
  private func cleanup() {
    urlData.count = 0
    statusData.count = 0

    headerKeyData.count = 0
    headerValueData.count = 0
    headerChunkWasValue = false

    message = nil
  }
}

// MARK: HTTPParser callbacks

private extension HTTPParser {
  /// Raised when the parser starts a new message.
  func messageBegin(rawParser: RawParser) -> Int32 {
    message = rawParser.isParsingRequest ? HTTPRequest() : HTTPResponse()
    return continueParsing
  }

  /// Raised when the parser parsed part of the URL.
  func parsedURL(rawParser: RawParser, chunk: RawChunkPointer?, count: Int) -> Int32 {
    urlData.append(chunk, count: count)

    // Not done parsing the URI? Continue
    guard rawParser.isURLComplete else { return continueParsing }

    // Check that the URI is valid
    guard let uriString = String(data: urlData, encoding: .utf8),
      let uriComponents = URLComponents(string: uriString) else { return stopParsing }

    // Set the URI, method and the host header
    request?.uri = URI(components: uriComponents)
    request?.method = rawParser.httpMethod
    request?.setHostHeader(host: uriComponents.host, port: uriComponents.port)

    return continueParsing
  }

  /// Raised when the parser parsed part of the status.
  func parsedStatus(rawParser: RawParser, chunk: RawChunkPointer?, count: Int) -> Int32 {
    statusData.append(chunk, count: count)

    // Not done parsing the status? Continue
    guard rawParser.isStatusComplete else { return continueParsing }

    // Check that the status is valid
    guard let phrase = String(data: statusData, encoding: .utf8) else { return stopParsing }

    // Set the status
    response?.status = HTTPStatus(code: rawParser.httpStatusCode, phrase: phrase)

    return continueParsing
  }

  /// Raised when the parser parsed part of a header key.
  func parsedHeaderKey(chunk: RawChunkPointer?, count: Int) -> Int32 {
    // For each header we first get key chunks and then value chunks,
    // when we get to a key chunk after a value chunk it means a single header is done
    if headerChunkWasValue {
      guard headerComplete() else { return stopParsing }
    }

    headerKeyData.append(chunk, count: count)
    return continueParsing
  }

  /// Raised when the parser parsed part of a header value.
  func parsedHeaderValue(chunk: RawChunkPointer?, count: Int) -> Int32 {
    headerChunkWasValue = true

    headerValueData.append(chunk, count: count)
    return continueParsing
  }

  /// Raised when a single header key and value is complete.
  func headerComplete() -> Bool {
    // Reset after we processed them
    defer {
      headerKeyData.count = 0
      headerValueData.count = 0
      headerChunkWasValue = false
    }

    // Make sure that the header data consists of valid String content
    guard let headerKey = String(bytes: headerKeyData, encoding: .utf8) else { return false }
    guard let headerValue = String(bytes: headerValueData, encoding: .utf8) else { return false }

    // If the header already exists add it comma separated
    if let existingValue = message?.headers[headerKey] {
      message?.headers[headerKey] = "\(existingValue),\(headerValue)"
    } else {
      message?.headers[headerKey] = headerValue
    }

    return true
  }

  /// Raised when the parser parsed the headers.
  func headersComplete(rawParser: RawParser) -> Int32 {
    guard let message = message else { return stopParsing }

    // Set the HTTP version
    message.version = rawParser.httpVersion

    // Reserve capacity for the body
    if let contentLength = message.headers.contentLength {
      message.body.reserveCapacity(contentLength)
    }

    // Complete the last header
    if headerChunkWasValue {
      guard headerComplete() else { return stopParsing }
    }

    // Call the delegate
    delegate?.parser(self, didParseHeadersOfMessage: message)

    return continueParsing
  }

  /// Raised when the parser parsed part of the body.
  func parsedBody(chunk: RawChunkPointer?, count: Int) -> Int32 {
    message?.body.append(chunk, count: count)
    return continueParsing
  }

  /// Raised when the parser parsed the whole message.
  func messageComplete(rawParser: RawParser) -> Int32 {
    guard let message = message else { return stopParsing }

    // Inform our delegate and cleanup
    delegate?.parser(self, didCompleteMessage: message)
    cleanup()

    return continueParsing
  }
}

// MARK: Data extensions

private extension Data {
  /// Appends the bytes to the data object.
  mutating func append(_ chunk: RawChunkPointer?, count: Int) {
    guard let chunk = chunk else { return }
    self.append(UnsafeRawPointer(chunk).assumingMemoryBound(to: UInt8.self), count: count)
  }
}

// MARK: RawParser extensions

private extension RawParser {
  /// Returns the content length header.
  var contentLength: Int {
    return content_length > Int.max ? 0 : Int(content_length)
  }

  /// Returns a boolean indicating if the parser is ready to parse.
  var isReady: Bool {
    return http_errno == HPE_OK.rawValue
  }

  /// Returns the error that occurred during parsing.
  var httpError: HTTPError? {
    if http_errno == HPE_OK.rawValue { return nil }
    return HTTPError(code: RawParserErrorCode(http_errno))
  }

  /// Returns the HTTP method.
  var httpMethod: HTTPMethod {
    let methodCode = http_method(method)
    let methodName = String(cString: http_method_str(methodCode))
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

  /// Returns a boolean indicating if the parser is parsing a HTTP request.
  var isParsingRequest: Bool {
    return type == HTTP_REQUEST.rawValue
  }

  /// Returns a boolean indicating if the parser is parsing a HTTP request.
  var isParsingResponse: Bool {
    return type == HTTP_RESPONSE.rawValue
  }

  /// Returns a boolean indicating if the status has been fully parsed.
  var isStatusComplete: Bool {
    return state >= 16
  }

  /// Returns a boolean indicating if the URL has been fully parsed.
  var isURLComplete: Bool {
    return state >= 31
  }

  /// Returns the parser that is linked to the raw parser.
  var parser: HTTPParser {
    get { return Unmanaged<HTTPParser>.fromOpaque(data).takeUnretainedValue() }
    set { data = Unmanaged.passUnretained(newValue).toOpaque() }
  }

  /// Creates a new RawParser instance.
  static func create() -> RawParser {
    var parser = RawParser()
    http_parser_init(&parser, HTTP_BOTH)
    return parser
  }

  /// Creates a new RawParserSettings instance.
  static func createSettings() -> RawParserSettings {
    var settings = RawParserSettings()
    http_parser_settings_init(&settings)
    return settings
  }

  /// Resets the parser.
  func reset() {
    var me = self
    http_parser_init(&me, HTTP_BOTH)
  }
}

// MARK: HTTPParserDelegate defaults

public extension HTTPParserDelegate {
  func parser(_ parser: HTTPParser, didParseHeadersOfMessage message: HTTPMessage) {}
}

// MARK: RawParserErrorCode to HTTPError mapping

private extension HTTPError {
  init(code: RawParserErrorCode) {
    switch code {
    case HPE_INVALID_EOF_STATE:
      self = .unexpectedStreamEnd
    case HPE_CLOSED_CONNECTION:
      self = .connectionShouldBeClosed
    case HPE_INVALID_VERSION:
      self = .invalidVersion
    case HPE_INVALID_METHOD:
      self = .invalidMethod
    case HPE_INVALID_URL, HPE_INVALID_HOST, HPE_INVALID_PORT, HPE_INVALID_PATH, HPE_INVALID_QUERY_STRING, HPE_INVALID_FRAGMENT:
      self = .invalidURI
    case HPE_INVALID_HEADER_TOKEN:
      self = .invalidHeader
    case HPE_INVALID_CONTENT_LENGTH:
      self = .invalidContentLength
    case HPE_HEADER_OVERFLOW:
      self = .headerOverflow
    default:
      self = .parseFailed(code: Int(code.rawValue))
    }
  }
}
