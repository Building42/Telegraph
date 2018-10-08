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

  init(_ name: String) {
    // According to RFC 7230 header names are case insensitive
    self.name = name.lowercased()
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

// MARK: Common headers

extension HTTPHeaderName {
  static let accept = HTTPHeaderName("accept")
  static let authorization = HTTPHeaderName("authorization")
  static let cacheControl = HTTPHeaderName("cache-Control")
  static let connection = HTTPHeaderName("connection")
  static let cookie = HTTPHeaderName("cookie")
  static let contentDisposition = HTTPHeaderName("content-disposition")
  static let contentEncoding = HTTPHeaderName("content-encoding")
  static let contentLength = HTTPHeaderName("content-length")
  static let contentType = HTTPHeaderName("content-type")
  static let date = HTTPHeaderName("date")
  static let referer = HTTPHeaderName("referer")
  static let host = HTTPHeaderName("host")
  static let lastModified = HTTPHeaderName("last-modified")
  static let server = HTTPHeaderName("server")
  static let setCookie = HTTPHeaderName("set-cookie")
  static let transferEncoding = HTTPHeaderName("transfer-encoding")
  static let userAgent = HTTPHeaderName("user-agent")
  static let upgrade = HTTPHeaderName("upgrade")
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

  public var contentType: String? {
    get { return self[.contentType] }
    set { self[.contentType] = newValue }
  }

  public var date: String? {
    get { return self[.date] }
    set { self[.date] = newValue }
  }

  public var referer: String? {
    get { return self[.referer] }
    set { self[.referer] = newValue }
  }

  public var host: String? {
    get { return self[.host] }
    set { self[.host] = newValue }
  }

  public var lastModified: String? {
    get { return self[.lastModified] }
    set { self[.lastModified] = newValue }
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

// MARK: Deprecated

@available(*, deprecated, message: "use HTTPHeaderName")
typealias HTTPHeader = HTTPHeaderName

@available(*, deprecated, message: "use Dictionary")
typealias CustomKeyIndexable = Dictionary

public extension HTTPHeaderName {
  @available(*, deprecated, message: "no longer available, test manually that name starts with x-")
  public var isCustom: Bool { return name.hasPrefix("x-") }
}
