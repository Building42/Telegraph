//
//  HTTPHeader.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/8/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public typealias HTTPHeaders = [HTTPHeader: String]

public struct HTTPHeader {
  public let name: String
  public var isCustom: Bool { return name.hasPrefix("X-") }

  init(_ name: String) {
    self.name = name
  }
}

// MARK: Dictionary implicit key conversion

public protocol CustomKeyIndexable {
  associatedtype Key
  associatedtype Value

  subscript(key: Key) -> Value? { get set }
}

extension CustomKeyIndexable where Key == HTTPHeader, Value == String {
  subscript(key: String) -> String? {
    get { return self[HTTPHeader(key)] }
    set { self[HTTPHeader(key)] = newValue }
  }
}

extension Dictionary: CustomKeyIndexable {}

// MARK: CustomStringConvertible implementation

extension HTTPHeader: CustomStringConvertible {
  public var description: String { return name }
}

// MARK: Equatable implementation

extension HTTPHeader: Equatable {
  public static func == (lhs: HTTPHeader, rhs: HTTPHeader) -> Bool {
    return lhs.name.lowercased() == rhs.name.lowercased()
  }
}

// MARK: Hashable implementation

extension HTTPHeader: Hashable {
  public var hashValue: Int {
    return name.lowercased().hashValue
  }
}

// MARK: ExpressibleByStringLiteral implementation

extension HTTPHeader: ExpressibleByStringLiteral {
  public init(stringLiteral string: String) {
    self.init(string)
  }

  public init(extendedGraphemeClusterLiteral string: String) {
    self.init(string)
  }

  public init(unicodeScalarLiteral string: String) {
    self.init(string)
  }
}

// MARK: Common headers

extension CustomKeyIndexable where Key == HTTPHeader, Value == String {
  public var accept: String? {
    get { return self["Accept"] }
    set { self["Accept"] = newValue }
  }

  public var authorization: String? {
    get { return self["Authorization"] }
    set { self["Authorization"] = newValue }
  }

  public var cacheControl: String? {
    get { return self["Cache-Control"] }
    set { self["Cache-Control"] = newValue }
  }

  public var connection: String? {
    get { return self["Connection"] }
    set { self["Connection"] = newValue }
  }

  public var cookie: String? {
    get { return self["Cookie"] }
    set { self["Cookie"] = newValue }
  }

  public var contentDisposition: String? {
    get { return self["Content-Disposition"] }
    set { self["Content-Disposition"] = newValue }
  }

  public var contentEncoding: String? {
    get { return self["Content-Encoding"] }
    set { self["Content-Enconding"] = newValue }
  }

  public var contentLength: Int? {
    get { return Int(self["Content-Length"] ?? "") }
    set { self["Content-Length"] = newValue == nil ? nil : "\(newValue!)" }
  }

  public var contentType: String? {
    get { return self["Content-Type"] }
    set { self["Content-Type"] = newValue }
  }

  public var date: String? {
    get { return self["Date"] }
    set { self["Date"] = newValue }
  }

  public var referer: String? {
    get { return self["Referer"] }
    set { self["Referer"] = newValue }
  }

  public var host: String? {
    get { return self["Host"] }
    set { self["Host"] = newValue }
  }

  public var lastModified: String? {
    get { return self["Last-Modified"] }
    set { self["Last-Modified"] = newValue }
  }

  public var server: String? {
    get { return self["Server"] }
    set { self["Server"] = newValue }
  }

  public var setCookie: String? {
    get { return self["Set-Cookie"] }
    set { self["Set-Cookie"] = newValue }
  }

  public var transferEncoding: String? {
    get { return self["Transfer-Encoding"] }
    set { self["Transfer-Encoding"] = newValue }
  }

  public var userAgent: String? {
    get { return self["User-Agent"] }
    set { self["User-Agent"] = newValue }
  }

  public var upgrade: String? {
    get { return self["Upgrade"] }
    set { self["Upgrade"] = newValue }
  }
}
