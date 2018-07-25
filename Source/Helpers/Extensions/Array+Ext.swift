//
//  Array+Ext.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/19/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension Array {
  public func first<T>(ofType: T.Type) -> T? {
    return first(where: { $0 as? T != nil }) as? T
  }

  public func filter<T>(ofType: T.Type) -> [T] {
    return compactMap { $0 as? T }
  }
}
