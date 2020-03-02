//
//  RouteTests.swift
//  Telegraph Tests
//
//  Created by Yvo van Beek on 7/8/19.
//  Copyright © 2019 Building42. All rights reserved.
//

import XCTest
@testable import Telegraph

class RouteTests: XCTestCase {
  /// Tests a simple route.
  func testRoute() {
    let route = try? HTTPRoute(uri: "/hello") { _ in return nil }
    XCTAssertNotNil(route, "Route could not be created")

    // The route should match the exact path
    let (match1, _) = route!.canHandle(path: "/hello")
    XCTAssertTrue(match1, "Route did not match")

    // The route should not match a different path
    let (match2, _) = route!.canHandle(path: "/bob")
    XCTAssertFalse(match2, "Route should not have matched")

    // The route should allow all methods (by default)
    XCTAssertTrue(route!.canHandle(method: .GET), "Route could not handle GET")
    XCTAssertTrue(route!.canHandle(method: .POST), "Route could not handle POST")
  }

  /// Tests a route that only allows specific HTTP methods.
  func testRouteMethods() {
    let route = try? HTTPRoute(methods: [.DELETE], uri: "/") { _ in return nil }
    XCTAssertNotNil(route, "Route could not be created")

    // The route should only allow the DELETE method
    XCTAssertTrue(route!.canHandle(method: .DELETE), "Route could not handle DELETE")
    XCTAssertFalse(route!.canHandle(method: .GET), "Route should not handle GET")
    XCTAssertFalse(route!.canHandle(method: .POST), "Route should not handle POST")
  }

  /// Tests a route that only allows specific HTTP methods.
  func testRouteParameters() {
    let route = try? HTTPRoute(uri: "/hello/:name/:age") { _ in return nil }
    XCTAssertNotNil(route, "Route could not be created")

    // The route should have two parameters
    XCTAssertEqual(route!.params, ["name", "age"], "Route parameters are incorrect")

    // The route should match the following path and return the correct parameters
    let (match1, params1) = route!.canHandle(path: "/hello/bob/20")
    XCTAssertTrue(match1, "Route did not match")
    XCTAssertEqual(params1["name"], "bob", "Route name parameter incorrect")
    XCTAssertEqual(params1["age"], "20", "Route age parameter incorrect")
    XCTAssertEqual(params1.count, 2, "Route parameter count incorrect")

    // The route should match even if it contains special characters
    let (match2, params2) = route!.canHandle(path: "/hello/bob@bob.com=great/old")
    XCTAssertTrue(match2, "Route did not match")
    XCTAssertEqual(params2["name"], "bob@bob.com=great", "Route name parameter incorrect")
    XCTAssertEqual(params2["age"], "old", "Route age parameter incorrect")
  }

  /// Tests a route that has optional start and end slashes.
  func testRouteOptionalSlash() {
    let route1 = try? HTTPRoute(uri: "hello") { _ in return nil }
    XCTAssertNotNil(route1, "Route could not be created")

    let route2 = try? HTTPRoute(uri: "hello(/)") { _ in return nil }
    XCTAssertNotNil(route2, "Route could not be created")

    // The route should match the path, start slash in the route is optional
    let (match1, _) = route1!.canHandle(path: "/hello")
    XCTAssertTrue(match1, "Route did not match")

    // The route should match the path, end slash should normally be not allowed
    let (match2, _) = route1!.canHandle(path: "/hello/")
    XCTAssertFalse(match2, "Route should not match")

    // The route should match the path, make sure the route still works
    let (match3, _) = route2!.canHandle(path: "/hello")
    XCTAssertTrue(match3, "Route did not match")

    // The route should match the path, end slash in the route is optional
    let (match4, _) = route2!.canHandle(path: "/hello/")
    XCTAssertTrue(match4, "Route did not match")
  }

  /// Tests a route that contains a wildcard to allow paths of any depth.
  func testRouteWildcard() {
    let route = try? HTTPRoute(uri: "/hello/*") { _ in return nil }
    XCTAssertNotNil(route, "Route could not be created")

    // The route should match the path, make sure the route still works
    let (match1, _) = route!.canHandle(path: "/hello")
    XCTAssertTrue(match1, "Route did not match")

    // The route should match the path and a nested resource
    let (match2, _) = route!.canHandle(path: "/hello/12345.html")
    XCTAssertTrue(match2, "Route did not match")

    // The route should match the path and deeper paths
    let (match3, _) = route!.canHandle(path: "/hello/abc/def/ghi/")
    XCTAssertTrue(match3, "Route did not match")
  }

  /// Tests a route that contains no specific uri or methods.
  func testRouteMatchAll() {
    let route = try? HTTPRoute { _ in return nil }
    XCTAssertNotNil(route, "Route could not be created")

    // The route should match any path
    let (match1, _) = route!.canHandle(path: "test")
    let (match2, _) = route!.canHandle(path: "/hello")
    let (match3, _) = route!.canHandle(path: "/abc/=*=/()/123.html")
    XCTAssertTrue(match1, "Route did not match")
    XCTAssertTrue(match2, "Route did not match")
    XCTAssertTrue(match3, "Route did not match")

    // The route should allow all methods
    XCTAssertTrue(route!.canHandle(method: .GET), "Route could not handle GET")
    XCTAssertTrue(route!.canHandle(method: .PATCH), "Route could not handle PATCH")
  }
}
