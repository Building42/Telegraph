//
//  HTTPParser.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/31/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation
import HTTPParserC

public protocol HTTPParserDelegate: class {
  func parser(_ parser: HTTPParser, didParseHeadersOfMessage message: HTTPMessage)
  func parser(_ parser: HTTPParser, didCompleteMessage message: HTTPMessage)
}

public class HTTPParser {
  public weak var delegate: HTTPParserDelegate?
  public private(set) var message: HTTPMessage?

  private var cParser: http_parser
  private var cParserSettings: http_parser_settings

  private var uriFragment = ""
  private var statusFragment = ""
  private var headerKeyFragment = ""
  private var headerValueFragment = ""
  private var headerLastAction = 0

  public init() {
    // Create a new instance of the C HTTP parser
    cParser = http_parser()
    http_parser_init(&cParser, HTTP_BOTH)

    // Provide the C HTTP parser with callbacks for the message parts
    cParserSettings = http_parser_settings()
    http_parser_settings_init(&cParserSettings)

    cParserSettings.on_message_begin = onMessageBegin
    cParserSettings.on_url = onParsedURL
    cParserSettings.on_status = onParsedStatus
    cParserSettings.on_header_field = onParsedHeaderField
    cParserSettings.on_header_value = onParsedHeaderValue
    cParserSettings.on_headers_complete = onHeadersComplete
    cParserSettings.on_body = onParsedBody
    cParserSettings.on_message_complete = onMessageComplete

    // Give the parser a reference to this instance for the callbacks
    // We can't reference self unless we defer this call after initialization has finished
    cParser.data = Unmanaged.passUnretained(self).toOpaque()
  }

  @discardableResult public func parse(data: Data) throws -> Int {
    // Parse the incoming data, return how many bytes were parsed
    let bytesParsed = data.withUnsafeBytes {
      http_parser_execute(&cParser, &cParserSettings, $0, data.count)
    }

    // Was there a parser error?
    let error = cParser.http_errno
    if error != 0 {
      throw HTTPError(code: http_errno(error))
    }

    return bytesParsed
  }

  private func unsafePointer() -> UnsafeMutableRawPointer {
    return Unmanaged.passUnretained(self).toOpaque()
  }
}

// MARK: HTTPParser callbacks

extension HTTPParser {
  private var request: HTTPRequest? { return message as? HTTPRequest }
  private var response: HTTPResponse? { return message as? HTTPResponse }

  private func reset() {
    message = nil
    uriFragment = ""
    statusFragment = ""
    headerKeyFragment = ""
    headerValueFragment = ""
    headerLastAction = 0
  }

  fileprivate func messageBegin() -> Int32 {
    return continueParsing
  }

  fileprivate func parsedURI(cParser: http_parser, fragment: String) -> Int32 {
    // Start a new request if this is the first fragment
    if request == nil { message = HTTPRequest() }

    // Store the uri fragment
    uriFragment += fragment

    // Done parsing the uri? And is it valid?
    guard cParser.isURIComplete else { return continueParsing }
    guard let components = URLComponents(string: uriFragment) else { return stopParsing }

    // Set the uri and the host header
    request?.uri = URI(components: components)
    request?.setHostHeader(host: components.host, port: components.port)

    return continueParsing
  }

  fileprivate func parsedStatus(cParser: http_parser, fragment: String) -> Int32 {
    // Start a new response if this is the first fragment
    if response == nil { message = HTTPResponse() }

    // Store the status fragment
    statusFragment += fragment

    // Done parsing the status?
    if cParser.isStatusComplete {
      response?.status = HTTPStatus(code: cParser.httpStatusCode, phrase: statusFragment)
    }

    return continueParsing
  }

  fileprivate func parsedHeaderKey(fragment: String) -> Int32 {
    // Ready for the next header?
    if headerLastAction != 1 {
      headerLastAction = 1
      headerKeyFragment = ""
      headerValueFragment = ""
    }

    // Combine the header key fragments, we'll store it when we encounter a value
    headerKeyFragment += fragment

    return continueParsing
  }

  fileprivate func parsedHeaderValue(fragment: String) -> Int32 {
    // Is this the start of a new header value?
    if headerLastAction != 2 {
      headerLastAction = 2

      // Did we see this header before? Comma separate the header values
      if let existingValue = message?.headers[headerKeyFragment] {
        headerValueFragment = existingValue + ","
      }
    }

    // Store the header value fragment
    headerValueFragment += fragment
    message?.headers[headerKeyFragment] = headerValueFragment

    return continueParsing
  }

  fileprivate func headersComplete() -> Int32 {
    // We're done with the headers
    delegate?.parser(self, didParseHeadersOfMessage: message!)

    return continueParsing
  }

  fileprivate func parsedBody(fragment: Data) -> Int32 {
    // Store the body fragment
    message?.body.append(fragment)

    return continueParsing
  }

  fileprivate func messageComplete(cParser: http_parser) -> Int32 {
    // Set the http version and method
    message?.version = cParser.httpVersion
    request?.method = HTTPMethod(rawValue: cParser.httpMethodName)

    // Does the parser instruct us to not keep alive?
    if !cParser.httpKeepAlive {
      message?.keepAlive = false
    }

    // We're done with the message
    delegate?.parser(self, didCompleteMessage: message!)

    // Reset for the next message
    reset()

    return continueParsing
  }
}

// MARK: CParser helpers

private typealias CParserPointer = UnsafeMutablePointer<http_parser>
private typealias BytesPointer = UnsafePointer<Int8>

private let continueParsing: Int32 = 0
private let stopParsing: Int32 = -1

private extension Data {
  init(bytes: BytesPointer?, count: Int) {
    if let bytes = bytes {
      let unsafeBytes = UnsafeMutablePointer(mutating: bytes)
      self.init(bytesNoCopy: unsafeBytes, count: count, deallocator: .none)
    } else {
      self.init()
    }
  }
}

private extension String {
  init(bytes: BytesPointer?, count: Int) {
    let data = Data(bytes: bytes, count: count)
    self.init(data: data, encoding: .utf8)!
  }
}

private extension http_parser {
  var httpKeepAlive: Bool {
    var mySelf = self
    return http_should_keep_alive(&mySelf) != 0
  }

  var httpMethodName: String {
    let methodCode = http_method(method)
    return String(cString: http_method_str(methodCode))
  }

  var httpStatusCode: Int {
    return Int(status_code)
  }

  var httpVersion: HTTPVersion {
    return HTTPVersion(UInt(http_major), UInt(http_minor))
  }

  var isStatusComplete: Bool {
    return state >= 16
  }

  var isURIComplete: Bool {
    return state >= 31
  }

  var parser: HTTPParser? {
    return Unmanaged<HTTPParser>.fromOpaque(data).takeUnretainedValue()
  }
}

// MARK: CParser callbacks

private func onMessageBegin(cParserPointer: CParserPointer?) -> Int32 {
  guard let cParser = cParserPointer?.pointee, let parser = cParser.parser else { return stopParsing }
  return parser.messageBegin()
}

private func onHeadersComplete(cParserPointer: CParserPointer?) -> Int32 {
    guard let cParser = cParserPointer?.pointee, let parser = cParser.parser else { return stopParsing }
  return parser.headersComplete()
}

private func onMessageComplete(cParserPointer: CParserPointer?) -> Int32 {
  guard let cParser = cParserPointer?.pointee, let parser = cParser.parser else { return stopParsing }
  return parser.messageComplete(cParser: cParser)
}

private func onParsedURL(cParserPointer: CParserPointer?, bytes: BytesPointer?, length: Int) -> Int32 {
  guard let cParser = cParserPointer?.pointee, let parser = cParser.parser else { return stopParsing }
  return parser.parsedURI(cParser: cParser, fragment: String(bytes: bytes, count: length))
}

private func onParsedStatus(cParserPointer: CParserPointer?, bytes: BytesPointer?, length: Int) -> Int32 {
  guard let cParser = cParserPointer?.pointee, let parser = cParser.parser else { return stopParsing }
  return parser.parsedStatus(cParser: cParser, fragment: String(bytes: bytes, count: length))
}

private func onParsedHeaderField(cParserPointer: CParserPointer?, bytes: BytesPointer?, length: Int) -> Int32 {
  guard let cParser = cParserPointer?.pointee, let parser = cParser.parser else { return stopParsing }
  return parser.parsedHeaderKey(fragment: String(bytes: bytes, count: length))
}

private func onParsedHeaderValue(cParserPointer: CParserPointer?, bytes: BytesPointer?, length: Int) -> Int32 {
  guard let cParser = cParserPointer?.pointee, let parser = cParser.parser else { return stopParsing }
  return parser.parsedHeaderValue(fragment: String(bytes: bytes, count: length))
}

private func onParsedBody(cParserPointer: CParserPointer?, bytes: BytesPointer?, length: Int) -> Int32 {
  guard let cParser = cParserPointer?.pointee, let parser = cParser.parser else { return stopParsing }
  return parser.parsedBody(fragment: Data(bytes: bytes, count: length))
}

// MARK: HTTPParserDelegate defaults

public extension HTTPParserDelegate {
  func parser(_ parser: HTTPParser, didParseHeadersOfMessage message: HTTPMessage) {}
}

// MARK: HTTPError mapping

private extension HTTPError {
  init(code: http_errno) {
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
