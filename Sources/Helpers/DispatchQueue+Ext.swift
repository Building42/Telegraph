//
//  DispatchQueue+Ext.swift
//  Telegraph
//
//  Created by Yvo van Beek on 4/5/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension DispatchQueue {
  /// Executes the block on the dispatch queue. The argument is passed as a weak reference.
  /// The block won't be called if the argument is already deallocated.
  func async<T: AnyObject>(weak arg: T, execute: @escaping (T) -> Void) {
    async { [weak arg] in
      guard let arg = arg else { return }
      execute(arg)
    }
  }
}
