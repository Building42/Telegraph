//
//  HTTPRoute.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/4/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public enum HTTPRouteError: Error {
  case invalidURI
}

public struct HTTPRoute {
  public let methods: Set<HTTPMethod>
  public let handler: HTTPRequest.Handler

  public let regex: Regex?
  public let params: [HTTPRequest.Params.Key]

  init(methods: Set<HTTPMethod> = [], regex: String?, handler: @escaping HTTPRequest.Handler) throws {
    self.methods = methods
    self.handler = handler

    let (regex, params) = try HTTPRoute.process(regex: regex)
    self.regex = regex
    self.params = params
  }

  init(methods: Set<HTTPMethod> = [], uri: String, handler: @escaping HTTPRequest.Handler) throws {
    try self.init(methods: methods, regex: HTTPRoute.pattern(basedOn: uri), handler: handler)
  }
}

// MARK: Route pattern processing

private extension HTTPRoute {
  static func pattern(basedOn uri: String) throws -> String {
    // Check if the uri is a valid route specification
    var pattern = URI(path: uri).path
    guard try Regex(pattern: "[-.:()\\w\\/]").matches(value: pattern) else { throw HTTPRouteError.invalidURI }

    // Allow easy optional slash pattern, for example /hello(/)
    pattern = pattern.replacingOccurrences(of: "(/)", with: "/?")

    // Limit what the regex will match by fixating the start and the end
    pattern.insert("^", at: pattern.startIndex)
    if !pattern.hasSuffix("*") { pattern.insert("$", at: pattern.endIndex) }
    return pattern
  }

  static func process(regex: String?) throws -> (Regex?, [String]) {
    // If no regex is specified this route will match all uris
    guard var pattern = regex else { return (nil, []) }

    // Extract the route parameters, for example /user/:id
    let paramRegex = try Regex(pattern: ":([\\w]+)")
    let params = paramRegex.matchAll(in: pattern).flatMap { $0.groupValues }

    // Change the parameters to capture groups
    if #available(iOS 9, *) {
      pattern = paramRegex.stringByReplacingMatches(in: pattern, withPattern: "(?<$1>[-.()\\\\w]+)")
    } else {
      pattern = paramRegex.stringByReplacingMatches(in: pattern, withPattern: "([-.()\\\\w]+)")
    }

    return (try Regex(pattern: pattern, options: .caseInsensitive), params)
  }
}

// MARK: Route handling

public extension HTTPRoute {
  func canHandle(method: HTTPMethod) -> Bool {
    return methods.contains(method)
  }

  func canHandle(path: String) -> (Bool, HTTPRequest.Params) {
    // Should we allow all patterns?
    guard let routeRegex = regex else { return (true, [:]) }

    // Test if the URI matches our route
    let matches = routeRegex.matchAll(in: path)
    if matches.isEmpty { return (false, [:]) }

    // If the URI matches our route, extract the params
    var routeParams = HTTPRequest.Params()
    let matchedParams = matches.flatMap { $0.groupValues }

    // Create a dictionary of parameter : parameter value
    for (key, value) in zip(params, matchedParams) {
      routeParams[key] = value
    }

    return (true, routeParams)
  }
}
