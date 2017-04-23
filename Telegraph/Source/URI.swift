//
//  URI.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/5/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public struct URI {
  fileprivate var components: URLComponents

  public var path: String {
    get { return components.path }
    set { components.path = newValue.isEmpty ? "/" : newValue }
  }

  public var query: String? {
    get { return components.query }
    set { components.query = newValue }
  }

  public var queryItems: [URLQueryItem]? {
    get { return components.queryItems }
    set { components.queryItems = newValue }
  }

  public var fragment: String? {
    get { return components.fragment }
    set { components.fragment = newValue }
  }

  public var string: String? {
    return components.string
  }

  public init(components: URLComponents) {
    self.components = URLComponents()
    self.path = components.path
    self.query = components.query
    self.fragment = components.fragment
  }

  public init(path: String = "/") {
    self.components = URLComponents()
    self.path = path
  }

  public init?(_ uri: String) {
    guard let components = URLComponents(string: uri) else { return nil }
    self.init(components: components)
  }

  public init?(url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    self.init(components: components)
  }
}

extension URI: CustomStringConvertible {
  public var description: String {
    return components.description
  }
}
