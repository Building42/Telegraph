//
//  URITests.swift
//  Telegraph Tests
//
//  Created by Yvo van Beek on 7/31/20.
//  Copyright © 2020 Building42. All rights reserved.
//

import XCTest
@testable import Telegraph

class URITests: XCTestCase {
  /// Tests the URI properties.
  func testURI() {
    let uri1 = URI("https://www.apple.com")
    let uri2 = URI("https://www.apple.com/hello")
    let uri3 = URI("https://www.apple.com?a=1")
    let uri4 = URI("https://www.apple.com/hello/world?a=1&b=2")

    XCTAssertEqual(uri1?.path, "/")
    XCTAssertEqual(uri2?.path, "/hello")
    XCTAssertEqual(uri3?.path, "/")
    XCTAssertEqual(uri4?.path, "/hello/world")

    XCTAssertNil(uri1?.query)
    XCTAssertNil(uri2?.query)
    XCTAssertEqual(uri3?.query, "a=1")
    XCTAssertEqual(uri4?.query, "a=1&b=2")

    XCTAssertNil(uri1?.queryItems)
    XCTAssertNil(uri2?.queryItems)
    XCTAssertEqual(uri3?.queryItems, [URLQueryItem(name: "a", value: "1")])
    XCTAssertEqual(uri4?.queryItems, [URLQueryItem(name: "a", value: "1"), URLQueryItem(name: "b", value: "2")])

    XCTAssertEqual(uri1?.string, "/")
    XCTAssertEqual(uri2?.string, "/hello")
    XCTAssertEqual(uri3?.string, "/?a=1")
    XCTAssertEqual(uri4?.string, "/hello/world?a=1&b=2")
  }

  /// Test the URI's percent encoding.
  func testURIPercentEncoding() {
    let uri1 = URI("https://www.apple.com/françois?query=xyz")
    let uri2 = URI("https://www.apple.com/fran%C3%A7ois?query=x%20y%20z")

    XCTAssertNil(uri1)

    XCTAssertEqual(uri2?.path, "/françois")
    XCTAssertEqual(uri2?.query, "query=x y z")
    XCTAssertEqual(uri2?.queryItems, [URLQueryItem(name: "query", value: "x y z")])
    XCTAssertEqual(uri2?.percentEncodedPath, "/fran%C3%A7ois")
    XCTAssertEqual(uri2?.percentEncodedQuery, "query=x%20y%20z")
    XCTAssertEqual(uri2?.string, "/fran%C3%A7ois?query=x%20y%20z")
  }

  /// Tests the URI constructors.
  func testURIConstructors() {
    let uriC1 = URI("hello?a=1")
    let uriC2 = URI(path: "hello", query: "a=1")
    let uriC3 = URI(components: URLComponents(string: "hello?a=1")!)
    let uriC4 = URI(url: URL(string: "https://www.apple.com/hello?a=1")!)

    XCTAssertEqual(uriC1?.path, "/hello")
    XCTAssertEqual(uriC2.path, "/hello")
    XCTAssertEqual(uriC3.path, "/hello")
    XCTAssertEqual(uriC4?.path, "/hello")

    XCTAssertEqual(uriC1?.query, "a=1")
    XCTAssertEqual(uriC2.query, "a=1")
    XCTAssertEqual(uriC3.query, "a=1")
    XCTAssertEqual(uriC4?.query, "a=1")

    XCTAssertEqual(uriC1?.queryItems, [URLQueryItem(name: "a", value: "1")])
    XCTAssertEqual(uriC2.queryItems, [URLQueryItem(name: "a", value: "1")])
    XCTAssertEqual(uriC3.queryItems, [URLQueryItem(name: "a", value: "1")])
    XCTAssertEqual(uriC4?.queryItems, [URLQueryItem(name: "a", value: "1")])

    XCTAssertEqual(uriC1?.percentEncodedPath, "/hello")
    XCTAssertEqual(uriC2.percentEncodedPath, "/hello")
    XCTAssertEqual(uriC3.percentEncodedPath, "/hello")
    XCTAssertEqual(uriC4?.percentEncodedPath, "/hello")

    XCTAssertEqual(uriC1?.percentEncodedQuery, "a=1")
    XCTAssertEqual(uriC2.percentEncodedQuery, "a=1")
    XCTAssertEqual(uriC3.percentEncodedQuery, "a=1")
    XCTAssertEqual(uriC4?.percentEncodedQuery, "a=1")

    XCTAssertEqual(uriC1?.string, "/hello?a=1")
    XCTAssertEqual(uriC2.string, "/hello?a=1")
    XCTAssertEqual(uriC3.string, "/hello?a=1")
    XCTAssertEqual(uriC4?.string, "/hello?a=1")
  }

  /// Tests the URI constructors with percent encoding
  func testURIConstructorsWithPercentEncoding2() {
    let uri = URI(percentEncodedPath: "/fran%C3%A7ois", percentEncodedQuery: "q=x%20y")

    XCTAssertEqual(uri.path, "/françois")
    XCTAssertEqual(uri.query, "q=x y")
    XCTAssertEqual(uri.queryItems, [URLQueryItem(name: "q", value: "x y")])
    XCTAssertEqual(uri.percentEncodedPath, "/fran%C3%A7ois")
    XCTAssertEqual(uri.percentEncodedQuery, "q=x%20y")
    XCTAssertEqual(uri.string, "/fran%C3%A7ois?q=x%20y")
  }

  /// Tests the URI with long path or querystring arguments.
  func testURIWithLongArgs() {
    let arg1 = "/abcdefghijklmnopqrstuvwxyz/abcdefghijklmnopqrstuvwxyz/abcdefghijklmnopqrstuvwxyz/abcdefghijklmnopqrstuvwxyz/abcdefghijklmnopqrstuvwxyz?a=1"
    let arg2 = "/abcdefghijklmnopqrstuvwxyz?a=1&b=2&c=3&d=4&e=5&f=6&g=7&h=8&i=9&j=10&k=11&l=12&m=13&n=14&o=15&p=16&q=17&r=18&s=19&t=20&u=21&v=22&w=23&x=24&y=25&z=26"

    XCTAssertEqual(URI(arg1)?.string, arg1)
    XCTAssertEqual(URI(arg1)?.queryItems?.count, 1)

    XCTAssertEqual(URI(arg2)?.string, arg2)
    XCTAssertEqual(URI(arg2)?.queryItems?.count, 26)
  }
}
