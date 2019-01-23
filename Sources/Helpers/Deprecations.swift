//
//  Deprecations.swift
//  Telegraph
//
//  Created by Yvo van Beek on 11/9/18.
//  Copyright © 2018 Building42. All rights reserved.
//

import Foundation

// MARK: - DateFormatter

public extension DateFormatter {
  @available(*, deprecated, message: "use DateFormatter.rfc1123 or Date's rfc1123 variable")
  var rfc7231: DateFormatter {
    return .rfc1123
  }
}

// MARK: - DispatchTimer

public extension DispatchTimer {
  /// Creates and starts a timer that runs after a while, optionally repeating with a specific interval.
  @available(*, deprecated, message: "no longer supported, use start(at:) to run the timer at a later time")
  static func run(after: TimeInterval, interval: TimeInterval = 0, queue: DispatchQueue, execute block: @escaping () -> Void) -> DispatchTimer {
    let timer = DispatchTimer(interval: interval, queue: queue, execute: block)
    timer.start(at: Date() + after)
    return timer
  }

  /// (Re)starts the timer, next run will be after the specified interval.
  @available(*, deprecated, message: "no longer supported, use start(at:) to run the timer at a later time")
  func start(after: TimeInterval) {
    start(at: Date() + after)
  }
}

// MARK: - HTTPHeader

@available(*, deprecated, message: "use HTTPHeaderName")
typealias HTTPHeader = HTTPHeaderName

@available(*, deprecated, message: "use Dictionary")
typealias CustomKeyIndexable = Dictionary

// MARK: - HTTPHeaderName

public extension HTTPHeaderName {
  @available(*, deprecated, message: "construct lower cased names manually")
  static var forceLowerCased = false
}

// MARK: - HTTPMethod

public extension HTTPMethod {
  @available(*, deprecated, message: "use HTTPMethod.GET")
  static var get = HTTPMethod.GET

  @available(*, deprecated, message: "use HTTPMethod.HEAD")
  static var head = HTTPMethod.HEAD

  @available(*, deprecated, message: "use HTTPMethod.DELETE")
  static var delete = HTTPMethod.DELETE

  @available(*, deprecated, message: "use HTTPMethod.OPTIONS")
  static var options = HTTPMethod.OPTIONS

  @available(*, deprecated, message: "use HTTPMethod.POST")
  static var post = HTTPMethod.POST

  @available(*, deprecated, message: "use HTTPMethod.PUT")
  static var put = HTTPMethod.PUT

  @available(*, deprecated, message: "use HTTPMethod(name:)")
  init(rawValue: String) {
    self.init(name: rawValue.uppercased())
  }

  @available(*, deprecated, message: "use HTTPMethod(name:)")
  static func method(_ name: String) -> HTTPMethod {
    return HTTPMethod(name: name)
  }
}

// MARK: - HTTPStatus

public extension HTTPStatus {
  @available(*, deprecated, message: "return nil from your handler (this status is used by Nginx, not part of the spec)")
  static let noResponse = HTTPStatus(code: 444, phrase: "No Response")
}

// MARK: - HTTPStatusCode

@available(*, deprecated, message: "use HTTPStatus, for example .ok or .notFound")
public typealias HTTPStatusCode = HTTPStatus

// MARK: - HTTPReponse

public extension HTTPResponse {
  @available(*, deprecated, message: "use DateFormatter.rfc1123 or Date's rfc1123 variable")
  static let dateFormatter = DateFormatter.rfc1123

  @available(*, deprecated, message: "data: has been renamed to body:")
  convenience init(_ status: HTTPStatus = .ok, data: Data) {
    self.init(status, body: data)
  }

  @available(*, deprecated, message: "use keepAlive instead, this setter only handles true properly")
  var closeAfterWrite: Bool {
    get { return !keepAlive }
    set { if newValue { headers.connection = "close" } }
  }
}

// MARK: - HTTPVersion

public extension HTTPVersion {
  @available(*, deprecated, message: "use HTTPVersion(major:, minor:)")
  init(_ major: UInt, _ minor: UInt) {
    self.init(major: major, minor: minor)
  }
}

// MARK: - Server

public extension Server {
  @available(*, deprecated, message: "use start(port:)")
  func start(onPort port: UInt16) throws {
    try start(port: Int(port))
  }

  @available(*, deprecated, message: "use start(port:interface:)")
  func start(onInterface interface: String?, port: UInt16 = 0) throws {
    try start(port: Int(port), interface: interface)
  }
}
