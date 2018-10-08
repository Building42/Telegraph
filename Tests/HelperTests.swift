//
//  HelperTests.swift
//  TelegraphTests
//
//  Created by Yvo van Beek on 2/16/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import XCTest
import Telegraph

class HelperTests: XCTestCase {
  /// Tests the SHA1 implementation.
  func testSHA1() {
    XCTAssertEqual(SHA1.hash("Hello").hexEncodedString(), "f7ff9e8b7bb2e09b70935a5d785e0cc5d9d0abf0", "SHA1 with short text incorrect")
    XCTAssertEqual(SHA1.hash("Héllö W0rld").hexEncodedString(), "e3d3f5df6baa0af053ad48519cd3b3cc7992c88a", "SHA1 special characters incorrect")
    XCTAssertEqual(SHA1.hash("Hello 😀😀😀😀").hexEncodedString(), "72e31a517f5e235471adf58143969983d29d83b9", "SHA1 emojis incorrect")

    let message = repeatElement("abcdefghijklmnopqrstuvwxyz", count: 20).joined(separator: "-")
    XCTAssertEqual(SHA1.hash(message).hexEncodedString(), "1fe4a8f5a091953630220c56b80d0b43efefea00", "SHA1 with long text incorrect")
  }

  /// Tests converting UInt16 values to arrays of UInt8 values.
  func testUInt16ToUInt8Array() {
    XCTAssertEqual(UInt16.min.bytes, [0, 0], "UInt16.min to bytes is incorrect")
    XCTAssertEqual(UInt16.max.bytes, [255, 255], "UInt16.max to bytes is incorrect")

    XCTAssertEqual(UInt16(24).bytes, [0, 24], "UInt16 '24' to bytes is incorrect")
    XCTAssertEqual(UInt16(12345).bytes, [48, 57], "UInt16 '12345' to bytes is incorrect")
  }

  /// Tests converting UInt32 values to arrays of UInt8 values.
  func testUInt32ToUInt8Array() {
    XCTAssertEqual(UInt32.min.bytes, [0, 0, 0, 0], "UInt32.min to bytes is incorrect")
    XCTAssertEqual(UInt32.max.bytes, [255, 255, 255, 255], "UInt32.max to bytes is incorrect")

    XCTAssertEqual(UInt32(24).bytes, [0, 0, 0, 24], "UInt32 '24' to bytes is incorrect")
    XCTAssertEqual(UInt32(12345).bytes, [0, 0, 48, 57], "UInt32 '12345' to bytes is incorrect")
    XCTAssertEqual(UInt32(534231).bytes, [0, 8, 38, 215], "UInt32 '534231' to bytes is incorrect")
    XCTAssertEqual(UInt32(1212121212).bytes, [72, 63, 128, 124], "UInt32 '1212121212' to bytes is incorrect")
  }

  /// Tests converting UInt64 values to arrays of UInt8 values.
  func testUInt64ToUInt8Array() {
    XCTAssertEqual(UInt64.min.bytes, [0, 0, 0, 0, 0, 0, 0, 0], "UInt64.min to bytes is incorrect")
    XCTAssertEqual(UInt64.max.bytes, [255, 255, 255, 255, 255, 255, 255, 255], "UInt64.max to bytes is incorrect")

    XCTAssertEqual((24 as UInt64).bytes, [0, 0, 0, 0, 0, 0, 0, 24], "UInt64 '24' to bytes is incorrect")
    XCTAssertEqual((12345 as UInt64).bytes, [0, 0, 0, 0, 0, 0, 48, 57], "UInt64 '12345' to bytes is incorrect")
    XCTAssertEqual((534231 as UInt64).bytes, [0, 0, 0, 0, 0, 8, 38, 215], "UInt64 '534231' to bytes is incorrect")
    XCTAssertEqual((1212121212 as UInt64).bytes, [0, 0, 0, 0, 72, 63, 128, 124], "UInt64 '1212121212' to bytes is incorrect")
    XCTAssertEqual((204060802040 as UInt64).bytes, [0, 0, 0, 47, 130, 248, 187, 248], "UInt64 '204060802040' to bytes is incorrect")
    XCTAssertEqual((78767574737271 as UInt64).bytes, [0, 0, 71, 163, 129, 79, 225, 119], "UInt64 '78767574737271' to bytes is incorrect")
    XCTAssertEqual((9999999999999999 as UInt64).bytes, [0, 35, 134, 242, 111, 192, 255, 255], "UInt64 '9999999999999999' to bytes is incorrect")
    XCTAssertEqual((1000100010001000100 as UInt64).bytes, [13, 225, 17, 169, 11, 249, 102, 164], "UInt64 '1000100010001000100' to bytes is incorrect")
  }
}
