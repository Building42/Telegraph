//
//  HTTPMethod.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/30/17.
//  Copyright © 2017 Building42. All rights reserved.
//

public struct HTTPMethod: Hashable {
  public let name: String
}

public extension HTTPMethod {
  static let GET = HTTPMethod(name: "GET")
  static let HEAD = HTTPMethod(name: "HEAD")
  static let DELETE = HTTPMethod(name: "DELETE")
  static let POST = HTTPMethod(name: "POST")
  static let PUT = HTTPMethod(name: "PUT")
  static let OPTIONS = HTTPMethod(name: "OPTIONS")
  static let CONNECT = HTTPMethod(name: "CONNECT")
  static let TRACE = HTTPMethod(name: "TRACE")
}

// MARK: CustomStringConvertible implementation

extension HTTPMethod: CustomStringConvertible {
  public var description: String {
    return name
  }
}

// MARK: ExpressibleByStringLiteral implementation

extension HTTPMethod: ExpressibleByStringLiteral {
  public init(stringLiteral string: String) {
    self.init(name: string)
  }
}

// MARK: Deprecated

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
