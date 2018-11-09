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
  /// Keeps the header keys as is or convert them all to lowercased.
  public static var forceLowerCased = false

  public let hashValue: Int
  private let name: String

  /// Creates a HTTPHeader name. Names are handled case insensitive according to RFC7230.
  init(_ name: String) {
    let lowerName = name.lowercased()
    self.name = HTTPHeaderName.forceLowerCased ? lowerName : name
    self.hashValue = lowerName.hashValue
  }
}

// MARK: Equatable implementation

extension HTTPHeaderName {
  public static func == (lhs: HTTPHeaderName, rhs: HTTPHeaderName) -> Bool {
    return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame
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

extension HTTPHeaderName {
  static let accept = HTTPHeaderName("Accept")
  static let authorization = HTTPHeaderName("Authorization")
  static let cacheControl = HTTPHeaderName("Cache-Control")
  static let connection = HTTPHeaderName("Connection")
  static let cookie = HTTPHeaderName("Cookie")
  static let contentDisposition = HTTPHeaderName("Content-Disposition")
  static let contentEncoding = HTTPHeaderName("Content-Encoding")
  static let contentLength = HTTPHeaderName("Content-Length")
  static let contentRange = HTTPHeaderName("Content-Range")
  static let contentType = HTTPHeaderName("Content-Type")
  static let date = HTTPHeaderName("Date")
  static let host = HTTPHeaderName("Host")
  static let lastModified = HTTPHeaderName("Last-Modified")
  static let range = HTTPHeaderName("Range")
  static let referer = HTTPHeaderName("Referer")
  static let server = HTTPHeaderName("Server")
  static let setCookie = HTTPHeaderName("Set-Cookie")
  static let transferEncoding = HTTPHeaderName("Transfer-Encoding")
  static let userAgent = HTTPHeaderName("User-Agent")
  static let upgrade = HTTPHeaderName("Upgrade")
}

extension Dictionary where Key == HTTPHeaderName, Value == String {
  public var accept: String? {
    get { return self[.accept] }
    set { self[.accept] = newValue }
  }

  public var authorization: String? {
    get { return self[.authorization] }
    set { self[.authorization] = newValue }
  }

  public var cacheControl: String? {
    get { return self[.cacheControl] }
    set { self[.cacheControl] = newValue }
  }

  public var connection: String? {
    get { return self[.connection] }
    set { self[.connection] = newValue }
  }

  public var cookie: String? {
    get { return self[.cookie] }
    set { self[.cookie] = newValue }
  }

  public var contentDisposition: String? {
    get { return self[.contentDisposition] }
    set { self[.contentDisposition] = newValue }
  }

  public var contentEncoding: String? {
    get { return self[.contentEncoding] }
    set { self[.contentEncoding] = newValue }
  }

  public var contentLength: Int? {
    get { return Int(self[.contentLength] ?? "") }
    set { self[.contentLength] = newValue == nil ? nil : "\(newValue!)" }
  }

  public var contentRange: String? {
    get { return self[.contentRange] }
    set { self[.contentRange] = newValue }
  }

  public var contentType: String? {
    get { return self[.contentType] }
    set { self[.contentType] = newValue }
  }

  public var date: String? {
    get { return self[.date] }
    set { self[.date] = newValue }
  }

  public var host: String? {
    get { return self[.host] }
    set { self[.host] = newValue }
  }

  public var lastModified: String? {
    get { return self[.lastModified] }
    set { self[.lastModified] = newValue }
  }

  public var range: String? {
    get { return self[.range] }
    set { self[.range] = newValue }
  }

  public var referer: String? {
    get { return self[.referer] }
    set { self[.referer] = newValue }
  }

  public var server: String? {
    get { return self[.server] }
    set { self[.server] = newValue }
  }

  public var setCookie: String? {
    get { return self[.setCookie] }
    set { self[.setCookie] = newValue }
  }

  public var transferEncoding: String? {
    get { return self[.transferEncoding] }
    set { self[.transferEncoding] = newValue }
  }

  public var userAgent: String? {
    get { return self[.userAgent] }
    set { self[.userAgent] = newValue }
  }

  public var upgrade: String? {
    get { return self[.upgrade] }
    set { self[.upgrade] = newValue }
  }
}
