//
//  HTTPVersion.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/31/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public struct HTTPVersion {
  public let major: UInt
  public let minor: UInt

  public init(_ major: UInt, _ minor: UInt) {
    self.major = major
    self.minor = minor
  }
}

// MARK: CustomStringConvertible

extension HTTPVersion: CustomStringConvertible {
  public var description: String {
    return "HTTP/\(major).\(minor)"
  }
}
