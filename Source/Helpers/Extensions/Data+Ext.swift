//
//  Data+Ext.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/13/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension Data {
  public static let crlf = Data(bytes: [0xD, 0xA])

  public init(randomNumberOfBytes count: Int) {
    self.init(count: count)
    withUnsafeMutableBytes { _ = SecRandomCopyBytes(kSecRandomDefault, count, $0) }
  }

  public mutating func mask(with maskBytes: [UInt8]) {
    let maskSize = maskBytes.count
    for i in 0..<count {
      self[i] ^= maskBytes[i % maskSize]
    }
  }
}
