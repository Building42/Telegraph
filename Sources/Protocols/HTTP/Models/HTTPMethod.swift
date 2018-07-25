//
//  HTTPMethod.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/30/17.
//  Copyright © 2017 Building42. All rights reserved.
//

public enum HTTPMethod {
  case delete
  case get
  case head
  case options
  case post
  case put
  case method(String)
}

extension HTTPMethod: RawRepresentable {
  public init(rawValue: String) {
    let method = rawValue.uppercased()

    switch method {
    case "DELETE": self = .delete
    case "GET": self = .get
    case "HEAD": self = .head
    case "OPTIONS": self = .options
    case "POST": self = .post
    case "PUT": self = .put
    default: self = .method(method)
    }
  }

  public var rawValue: String {
    switch self {
    case .delete: return "DELETE"
    case .get: return "GET"
    case .head: return "HEAD"
    case .options: return "OPTIONS"
    case .post: return "POST"
    case .put: return "PUT"
    case .method(let method): return method.uppercased()
    }
  }
}

// MARK: CustomStringConvertible implementation

extension HTTPMethod: CustomStringConvertible {
  public var description: String {
    return rawValue
  }
}

// MARK: Equatable implementation

extension HTTPMethod: Equatable {
  public static func == (lhs: HTTPMethod, rhs: HTTPMethod) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}

// MARK: Hashable implementation

extension HTTPMethod: Hashable {
  public var hashValue: Int {
    return rawValue.hashValue
  }
}

// MARK: ExpressibleByStringLiteral implementation

extension HTTPMethod: ExpressibleByStringLiteral {
  public init(stringLiteral string: String) {
    self.init(rawValue: string)
  }

  public init(extendedGraphemeClusterLiteral string: String) {
    self.init(rawValue: string)
  }

  public init(unicodeScalarLiteral string: String) {
    self.init(rawValue: string)
  }
}
