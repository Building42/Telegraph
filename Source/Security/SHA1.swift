//
//  SHA1.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/13/17.
//  Copyright © 2017 Building42. All rights reserved.
//
//  For more information see: https://tools.ietf.org/html/rfc3174
//

import Foundation

// Operator to rotate a word
infix operator <<< : BitwiseShiftPrecedence
private func <<< (lhs: UInt32, rhs: UInt32) -> UInt32 {
  return lhs << rhs | lhs >> (32 - rhs)
}

public struct SHA1 {
  // SHA1 magic numbers
  private var hash: [UInt32] = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]

  // The result as hexadecimal string
  public var hex: String {
    return String(format: "%08x%08x%08x%08x%08x", hash[0], hash[1], hash[2], hash[3], hash[4])
  }

  // The result as data
  public var data: Data {
    return Data(bytes: hash.flatMap { $0.bytes })
  }

  public init(string: String) {
    self.init(data: string.data(using: .utf8)!)
  }

  public init(data message: Data) {
    // SHA1 consists of [message][1][padding][data bit length] in 64 byte chunks

    // Create the two message bit-size words
    let messageBitSize = UInt64(message.count) * 8
    let largeSize = UInt32(truncatingIfNeeded: messageBitSize >> 32)
    let smallSize = UInt32(truncatingIfNeeded: messageBitSize)

    // Create a buffer to hold a chunk
    var chunk = [UInt32](repeating: 0x00000000, count: 80)
    let chunkSize = 64
    var index = 0, state = 0

    while true {
      var bytesInChunk = 0

      // If we aren't writing full chunks, make sure to clear the buffer
      if index + chunkSize > message.endIndex {
        for i in 0..<16 { chunk[i] = 0 }
      }

      // Is there still data left in the message?
      if index < message.endIndex {
        chunk.withUnsafeMutableBufferPointer { buffer in
          let startIndex = index
          let endIndex = min(message.endIndex, index + chunkSize)
          bytesInChunk = message.copyBytes(to: buffer, from: startIndex..<endIndex)
        }
      }

      // After the message, write the 1-bit by shifting it into the right word
      if state == 0 && bytesInChunk < chunkSize {
        chunk[bytesInChunk / 4] |= 0x80 << UInt32((bytesInChunk % 4) * 8)
        state = 1
      }

      // Write the message bit size in two words at the end of the chunk
      if chunkSize - bytesInChunk > 9 {
        chunk[14] = largeSize.bigEndian
        chunk[15] = smallSize.bigEndian
        state = 2
      }

      // Process the chunk
      process(chunk: &chunk)

      // Are we done? If so break, otherwise update the index
      if state == 2 { break }
      index += chunkSize
    }
  }

  private mutating func process(chunk: inout [UInt32]) {
    // The data is in the first 16 words, make sure that it is big endian
    for i in 0..<16 { chunk[i] = chunk[i].bigEndian }

    // Move every byte into a separate word, 0-16 is the original data, 16-80 will be the spread out words
    for i in 16..<80 { chunk[i] = (chunk[i - 3] ^ chunk[i - 8] ^ chunk[i - 14] ^ chunk[i - 16]) <<< 1 }

    // Define the SHA rotation macro
    var a = hash[0], b = hash[1], c = hash[2], d = hash[3], e = hash[4]
    var temp: UInt32 = 0
    let shaMacro = { (f: UInt32, k: UInt32, word: UInt32) in
      temp = a <<< 5 &+ f &+ e &+ k &+ word
      e = d
      d = c
      c = b <<< 30
      b = a
      a = temp
    }

    // Perform the rotations
    for i in 0...19 { shaMacro(d ^ (b & (c ^ d)), 0x5A827999, chunk[i]) }
    for i in 20...39 { shaMacro(b ^ c ^ d, 0x6ED9EBA1, chunk[i]) }
    for i in 40...59 { shaMacro((b & c) | (b & d) | (c & d), 0x8f1BBCDC, chunk[i]) }
    for i in 60...79 { shaMacro(b ^ c ^ d, 0xCA62C1D6, chunk[i]) }

    // Update the hash
    hash = [hash[0] &+ a, hash[1] &+ b, hash[2] &+ c, hash[3] &+ d, hash[4] &+ e]
  }
}
