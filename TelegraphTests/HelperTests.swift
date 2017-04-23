//
//  HelperTests.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/16/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import XCTest
import Telegraph

class HelperTests: XCTestCase {
  func testSHA1() {
    XCTAssertEqual(SHA1(string: "Hello").hex, "f7ff9e8b7bb2e09b70935a5d785e0cc5d9d0abf0", "SHA1 with short text incorrect")
    XCTAssertEqual(SHA1(string: "Héllö W0rld").hex, "e3d3f5df6baa0af053ad48519cd3b3cc7992c88a", "SHA1 special characters incorrect")
    XCTAssertEqual(SHA1(string: "Hello 😀😀😀😀").hex, "72e31a517f5e235471adf58143969983d29d83b9", "SHA1 emojis incorrect")

    let message = repeatElement("abcdefghijklmnopqrstuvwxyz", count: 20).joined(separator: "-")
    XCTAssertEqual(SHA1(string: message).hex, "1fe4a8f5a091953630220c56b80d0b43efefea00", "SHA1 with long text incorrect")
  }
}
