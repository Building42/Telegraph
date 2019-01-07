//
//  HTTPHeader.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/8/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public typealias HTTPHeaders = [HTTPHeaderName: String]

public struct HTTPHeaderName: Hashable {
  private let name: String
  private let nameInLowercase: String

  /// Creates a HTTPHeader name. Header names are case insensitive according to RFC7230.
  init(_ name: String) {
    self.name = name
    self.nameInLowercase = name.lowercased()
  }

  /// Returns a Boolean value indicating whether two names are equal.
  public static func == (lhs: HTTPHeaderName, rhs: HTTPHeaderName) -> Bool {
    return lhs.nameInLowercase == rhs.nameInLowercase
  }

  /// Hashes the name by feeding it into the given hasher.
  public func hash(into hasher: inout Hasher) {
    nameInLowercase.hash(into: &hasher)
  }
}

// MARK: CustomStringConvertible implementation

extension HTTPHeaderName: CustomStringConvertible {
  public var description: String {
    return name
  }
}

// MARK: ExpressibleByStringLiteral implementation

extension HTTPHeaderName: ExpressibleByStringLiteral {
  public init(stringLiteral string: String) {
    self.init(string)
  }
}

// MARK: Convenience methods

public extension Dictionary where Key == HTTPHeaderName, Value == String {
  static var empty: HTTPHeaders {
    return self.init(minimumCapacity: 3)
  }

  subscript(key: String) -> String? {
    get { return self[HTTPHeaderName(key)] }
    set { self[HTTPHeaderName(key)] = newValue }
  }
}

// MARK: Common headers

public extension HTTPHeaderName {
  static let accept = HTTPHeaderName("Accept")
  static let acceptCharset = HTTPHeaderName("Accept-Charset")
  static let acceptEncoding = HTTPHeaderName("Accept-Encoding")
  static let acceptLanguage = HTTPHeaderName("Accept-Language")
  static let acceptRanges = HTTPHeaderName("Accept-Ranges")
  static let age = HTTPHeaderName("Age")
  static let allow = HTTPHeaderName("Allow")
  static let authorization = HTTPHeaderName("Authorization")
  static let cacheControl = HTTPHeaderName("Cache-Control")
  static let connection = HTTPHeaderName("Connection")
  static let cookie = HTTPHeaderName("Cookie")
  static let contentDisposition = HTTPHeaderName("Content-Disposition")
  static let contentEncoding = HTTPHeaderName("Content-Encoding")
  static let contentLanguage = HTTPHeaderName("Content-Language")
  static let contentLength = HTTPHeaderName("Content-Length")
  static let contentRange = HTTPHeaderName("Content-Range")
  static let contentType = HTTPHeaderName("Content-Type")
  static let date = HTTPHeaderName("Date")
  static let eTag = HTTPHeaderName("ETag")
  static let expect = HTTPHeaderName("Expect")
  static let expires = HTTPHeaderName("Expires")
  static let forwarded = HTTPHeaderName("Forwarded")
  static let host = HTTPHeaderName("Host")
  static let lastModified = HTTPHeaderName("Last-Modified")
  static let location = HTTPHeaderName("Location")
  static let origin = HTTPHeaderName("Origin")
  static let pragma = HTTPHeaderName("Pragma")
  static let range = HTTPHeaderName("Range")
  static let referer = HTTPHeaderName("Referer")
  static let refresh = HTTPHeaderName("Refresh")
  static let server = HTTPHeaderName("Server")
  static let setCookie = HTTPHeaderName("Set-Cookie")
  static let strictTransportSecurity = HTTPHeaderName("Strict-Transport-Security")
  static let transferEncoding = HTTPHeaderName("Transfer-Encoding")
  static let userAgent = HTTPHeaderName("User-Agent")
  static let upgrade = HTTPHeaderName("Upgrade")
}

public extension Dictionary where Key == HTTPHeaderName, Value == String {
  var accept: String? {
    get { return self[.accept] }
    set { self[.accept] = newValue }
  }

  var acceptCharset: String? {
    get { return self[.acceptCharset] }
    set { self[.acceptCharset] = newValue }
  }

  var acceptEncoding: String? {
    get { return self[.acceptEncoding] }
    set { self[.acceptEncoding] = newValue }
  }

  var acceptLanguage: String? {
    get { return self[.acceptLanguage] }
    set { self[.acceptLanguage] = newValue }
  }

  var acceptRanges: String? {
    get { return self[.acceptRanges] }
    set { self[.acceptRanges] = newValue }
  }

  var age: String? {
    get { return self[.age] }
    set { self[.age] = newValue }
  }

  var allow: String? {
    get { return self[.allow] }
    set { self[.allow] = newValue }
  }

  var authorization: String? {
    get { return self[.authorization] }
    set { self[.authorization] = newValue }
  }

  var cacheControl: String? {
    get { return self[.cacheControl] }
    set { self[.cacheControl] = newValue }
  }

  var connection: String? {
    get { return self[.connection] }
    set { self[.connection] = newValue }
  }

  var cookie: String? {
    get { return self[.cookie] }
    set { self[.cookie] = newValue }
  }

  var contentDisposition: String? {
    get { return self[.contentDisposition] }
    set { self[.contentDisposition] = newValue }
  }

  var contentEncoding: String? {
    get { return self[.contentEncoding] }
    set { self[.contentEncoding] = newValue }
  }

  var contentLanguage: String? {
    get { return self[.contentLanguage] }
    set { self[.contentLanguage] = newValue }
  }

  var contentLength: Int? {
    get { return Int(self[.contentLength] ?? "") }
    set { self[.contentLength] = newValue == nil ? nil : "\(newValue!)" }
  }

  var contentRange: String? {
    get { return self[.contentRange] }
    set { self[.contentRange] = newValue }
  }

  var contentType: String? {
    get { return self[.contentType] }
    set { self[.contentType] = newValue }
  }

  var date: String? {
    get { return self[.date] }
    set { self[.date] = newValue }
  }

  var eTag: String? {
    get { return self[.eTag] }
    set { self[.eTag] = newValue }
  }

  var expect: String? {
    get { return self[.expect] }
    set { self[.expect] = newValue }
  }

  var expires: String? {
    get { return self[.expires] }
    set { self[.expires] = newValue }
  }

  var forwarded: String? {
    get { return self[.forwarded] }
    set { self[.forwarded] = newValue }
  }

  var host: String? {
    get { return self[.host] }
    set { self[.host] = newValue }
  }

  var lastModified: String? {
    get { return self[.lastModified] }
    set { self[.lastModified] = newValue }
  }

  var location: String? {
    get { return self[.location] }
    set { self[.location] = newValue }
  }

  var origin: String? {
    get { return self[.origin] }
    set { self[.origin] = newValue }
  }

  var pragma: String? {
    get { return self[.pragma] }
    set { self[.pragma] = newValue }
  }

  var range: String? {
    get { return self[.range] }
    set { self[.range] = newValue }
  }

  var referer: String? {
    get { return self[.referer] }
    set { self[.referer] = newValue }
  }

  var refresh: String? {
    get { return self[.refresh] }
    set { self[.refresh] = newValue }
  }

  var server: String? {
    get { return self[.server] }
    set { self[.server] = newValue }
  }

  var setCookie: String? {
    get { return self[.setCookie] }
    set { self[.setCookie] = newValue }
  }

  var strictTransportSecurity: String? {
    get { return self[.strictTransportSecurity] }
    set { self[.strictTransportSecurity] = newValue }
  }

  var transferEncoding: String? {
    get { return self[.transferEncoding] }
    set { self[.transferEncoding] = newValue }
  }

  var userAgent: String? {
    get { return self[.userAgent] }
    set { self[.userAgent] = newValue }
  }

  var upgrade: String? {
    get { return self[.upgrade] }
    set { self[.upgrade] = newValue }
  }
}
