//
//  URLTests.swift
//  Telegraph iOS
//
//  Created by Yvo van Beek on 8/28/20.
//  Copyright © 2020 Building42. All rights reserved.
//

import XCTest
@testable import Telegraph

class URLTests: XCTestCase {
  /// Tests the URL mime-type helper.
  func testURLMimeType() {
    let url1 = URL(string: "https://www.apple.com")
    let url2 = URL(string: "https://www.apple.com/hello")
    let url3 = URL(string: "https://www.apple.com/hello.wasm")
    let url4 = URL(string: "https://www.apple.com/hello.jpg")
    let url5 = URL(string: "https://www.apple.com/hello.png")
    let url6 = URL(string: "https://www.apple.com/hello.html")
    let url7 = URL(string: "https://www.apple.com/hello.mp4?hello=world")

    XCTAssertEqual(url1?.mimeType, "application/octet-stream")
    XCTAssertEqual(url2?.mimeType, "application/octet-stream")
    XCTAssertEqual(url3?.mimeType, "application/wasm")
    XCTAssertEqual(url4?.mimeType, "image/jpeg")
    XCTAssertEqual(url5?.mimeType, "image/png")
    XCTAssertEqual(url6?.mimeType, "text/html")
    XCTAssertEqual(url7?.mimeType, "video/mp4")
  }
}
