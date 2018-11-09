//
//  URI.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/5/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public struct URI {
  private var components: URLComponents

  /// Creates a URI from the provided path, query string.
  public init(path: String = "/", query: String? = nil) {
    self.components = URLComponents()
    self.path = path
    self.query = query
  }

  /// Creates a URI from URLComponents. Takes only the path, query string.
  public init(components: URLComponents) {
    self.init(path: components.path, query: components.query)
  }

  /// Creates a URI from the provided URL. Takes only the path, query string and fragment.
  public init?(url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    self.init(components: components)
  }

  /// Creates a URI from the provided string. Takes only the path, query string and fragment.
  public init?(_ string: String) {
    guard let components = URLComponents(string: string) else { return nil }
    self.init(components: components)
  }
}

public extension URI {
  /// The path of the URI (e.g. /index.html). Always starts with a slash.
  var path: String {
    get { return components.path }
    set { components.path = newValue.hasPrefix("/") ? newValue : "/\(newValue)" }
  }

  /// The query string of the URI (e.g. lang=en&page=home). Does not contain a question mark.
  var query: String? {
    get { return components.query }
    set { components.query = newValue }
  }

  /// The query string items of the URI as an array.
  var queryItems: [URLQueryItem]? {
    get { return components.queryItems }
    set { components.queryItems = newValue }
  }
}

public extension URI {
  /// Returns a URI indicating the root.
  static let root = URI(path: "/")

  /// Returns the part of the path that doesn't overlap.
  /// For example '/files/today' with argument '/files' returns 'today'.
  func relativePath(from path: String) -> String? {
    var result = self.path

    // Remove the part of the path that overlaps
    guard let range = result.range(of: path) else { return nil }
    result = result.replacingCharacters(in: range, with: "")

    // Remove leading slash
    if result.hasPrefix("/") { result.remove(at: result.startIndex) }

    return result
  }
}

extension URI: CustomStringConvertible {
  public var description: String {
    return components.description
  }
}
