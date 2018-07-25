//
//  HTTPStatusCode.swift
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
  case unprocessableEntity = 422
  case tooManyRequests = 429
  case requestHeaderFieldsTooLarge = 431
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

  public init(code: HTTPStatusCode) {
    self.code = code.rawValue

    switch code {
    case .switchingProtocols: phrase = "Switching Protocols"
    case .ok: phrase = "OK"
    case .created: phrase = "Created"
    case .noContent: phrase = "No Content"
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
    case .unprocessableEntity: phrase = "Unprocessable Entity"
    case .tooManyRequests: phrase = "Too Many Requests"
    case .requestHeaderFieldsTooLarge: phrase = "Request Header Fields Too Large"
    case .internalServerError: phrase = "Internal Server Error"
    case .notImplemented: phrase = "Not Implemented"
    case .badGateway: phrase = "Bad Gateway"
    case .serviceUnavailable: phrase = "Service Unavailable"
    case .gatewayTimeout: phrase = "Gateway Time-out"
    case .httpVersionNotSupported: phrase = "HTTP Version Not Supported"
    }
  }

  public init(code: Int, phrase: String = "") {
    self.code = code
    self.phrase = phrase
  }
}

// MARK: Helpers

extension HTTPStatus {
  public var isInformational: Bool {
    return code < 200
  }

  public var isSuccess: Bool {
    return code >= 200 && code < 300
  }

  public var supportsBody: Bool {
    return !(isInformational || self == HTTPStatusCode.noContent || self == HTTPStatusCode.notModified)
  }
}

// MARK: CustomStringConvertible implementation

extension HTTPStatus: CustomStringConvertible {
  public var description: String {
    return "\(code) - \(phrase)"
  }
}

// MARK: Equatable implementation

extension HTTPStatus: Equatable {
  public static func == (lhs: HTTPStatus, rhs: HTTPStatus) -> Bool {
    return lhs.code == rhs.code
  }

  public static func == (lhs: HTTPStatus, rhs: HTTPStatusCode) -> Bool {
    return lhs.code == rhs.rawValue
  }
}
