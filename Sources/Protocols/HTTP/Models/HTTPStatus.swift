//
//  HTTPStatus.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/30/17.
//  Copyright © 2017 Building42. All rights reserved.
//

public enum HTTPStatusCode: Int {
  case switchingProtocols = 101
  case ok = 200
  case created = 201
  case noContent = 204
  case partialContent = 206
  case movedPermanently = 301
  case notModified = 304
  case temporaryRedirect = 307
  case permanentRedirect = 308
  case badRequest = 400
  case unauthorized = 401
  case forbidden = 403
  case notFound = 404
  case methodNotAllowed = 405
  case lengthRequired = 411
  case payloadTooLarge = 413
  case uriTooLong = 414
  case rangeNotSatisfiable = 416
  case unprocessableEntity = 422
  case tooManyRequests = 429
  case requestHeaderFieldsTooLarge = 431
  case noResponse = 444
  case internalServerError = 500
  case notImplemented = 501
  case badGateway = 502
  case serviceUnavailable = 503
  case gatewayTimeout = 504
  case httpVersionNotSupported = 505
}

public struct HTTPStatus {
  public let code: Int
  public let phrase: String

  /// Creates a new HTTP status based on a HTTP status code.
  public init(code: HTTPStatusCode) {
    self.code = code.rawValue

    switch code {
    case .switchingProtocols: phrase = "Switching Protocols"
    case .ok: phrase = "OK"
    case .created: phrase = "Created"
    case .noContent: phrase = "No Content"
    case .partialContent: phrase = "Partial Content"
    case .movedPermanently: phrase = "Moved Permanently"
    case .notModified: phrase = "Not Modified"
    case .temporaryRedirect: phrase = "Temporary Redirect"
    case .permanentRedirect: phrase = "Permanent Redirect"
    case .badRequest: phrase = "Bad Request"
    case .unauthorized: phrase = "Unauthorized"
    case .forbidden: phrase = "Forbidden"
    case .notFound: phrase = "Not Found"
    case .methodNotAllowed: phrase = "Method Not Allowed"
    case .lengthRequired: phrase = "Length Required"
    case .payloadTooLarge: phrase = "Payload Too Large"
    case .uriTooLong: phrase = "URI Too Long"
    case .rangeNotSatisfiable: phrase = "Range Not Satisfiable"
    case .unprocessableEntity: phrase = "Unprocessable Entity"
    case .tooManyRequests: phrase = "Too Many Requests"
    case .requestHeaderFieldsTooLarge: phrase = "Request Header Fields Too Large"
    case .noResponse: phrase = "No Response"
    case .internalServerError: phrase = "Internal Server Error"
    case .notImplemented: phrase = "Not Implemented"
    case .badGateway: phrase = "Bad Gateway"
    case .serviceUnavailable: phrase = "Service Unavailable"
    case .gatewayTimeout: phrase = "Gateway Time-out"
    case .httpVersionNotSupported: phrase = "HTTP Version Not Supported"
    }
  }

  /// Creates a new HTTP status based on a code and a phrase.
  public init(code: Int, phrase: String = "") {
    self.code = code
    self.phrase = phrase
  }
}

// MARK: Initializers

public extension HTTPStatus {
  static let switchingProtocols = HTTPStatus(code: .switchingProtocols)
  static let ok = HTTPStatus(code: .ok)
  static let created = HTTPStatus(code: .created)
  static let noContent = HTTPStatus(code: .noContent)
  static let partialContent = HTTPStatus(code: .partialContent)
  static let movedPermanently = HTTPStatus(code: .movedPermanently)
  static let notModified = HTTPStatus(code: .notModified)
  static let temporaryRedirect = HTTPStatus(code: .temporaryRedirect)
  static let permanentRedirect = HTTPStatus(code: .permanentRedirect)
  static let badRequest = HTTPStatus(code: .badRequest)
  static let unauthorized = HTTPStatus(code: .unauthorized)
  static let forbidden = HTTPStatus(code: .forbidden)
  static let notFound = HTTPStatus(code: .notFound)
  static let methodNotAllowed = HTTPStatus(code: .methodNotAllowed)
  static let lengthRequired = HTTPStatus(code: .lengthRequired)
  static let payloadTooLarge = HTTPStatus(code: .payloadTooLarge)
  static let uriTooLong = HTTPStatus(code: .uriTooLong)
  static let rangeNotSatisfiable = HTTPStatus(code: .rangeNotSatisfiable)
  static let unprocessableEntity = HTTPStatus(code: .unprocessableEntity)
  static let tooManyRequests = HTTPStatus(code: .tooManyRequests)
  static let requestHeaderFieldsTooLarge = HTTPStatus(code: .requestHeaderFieldsTooLarge)
  static let noResponse = HTTPStatus(code: .noResponse)
  static let internalServerError = HTTPStatus(code: .internalServerError)
  static let notImplemented = HTTPStatus(code: .notImplemented)
  static let badGateway = HTTPStatus(code: .badGateway)
  static let serviceUnavailable = HTTPStatus(code: .serviceUnavailable)
  static let gatewayTimeout = HTTPStatus(code: .gatewayTimeout)
  static let httpVersionNotSupported = HTTPStatus(code: .httpVersionNotSupported)
}

// MARK: Helpers

public extension HTTPStatus {
  /// Returns a boolean indicating if the status is used for informational purposes (< 200).
  var isInformational: Bool {
    return code < 200
  }

  /// Returns a boolean inidicating if the status describes a succesful operation.
  var isSuccess: Bool {
    return code >= 200 && code < 300
  }

  /// Returns a boolean indicating if the the message should have a body when this status is used.
  var supportsBody: Bool {
    return !isInformational && self != HTTPStatusCode.noContent && self != HTTPStatusCode.notModified
  }
}

// MARK: CustomStringConvertible implementation

extension HTTPStatus: CustomStringConvertible {
  public var description: String {
    return "\(code) \(phrase)"
  }
}

// MARK: Equatable between HTTPStatus and HTTPStatusCode

extension HTTPStatus {
  public static func == (lhs: HTTPStatus, rhs: HTTPStatusCode) -> Bool {
    return lhs.code == rhs.rawValue
  }

  public static func != (lhs: HTTPStatus, rhs: HTTPStatusCode) -> Bool {
    return lhs.code != rhs.rawValue
  }

  public static func == (lhs: HTTPStatusCode, rhs: HTTPStatus) -> Bool {
    return lhs.rawValue == rhs.code
  }

  public static func != (lhs: HTTPStatusCode, rhs: HTTPStatus) -> Bool {
    return lhs.rawValue != rhs.code
  }
}
