//
//  Delegator.swift
//  Telegraph
//
//  Created by Yvo van Beek on 4/5/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public class Delegator<Delegate> {
  private let workQueue = DispatchQueue(label: "Telegraph.Delegator.work")

  private weak var innerDelegate: AnyObject?
  private var innerQueue: DispatchQueue?

  /// Returns the delegate.
  public var delegate: Delegate? {
    return workQueue.sync { innerDelegate as? Delegate }
  }

  /// Returns the delegate queue.
  public var queue: DispatchQueue? {
    return workQueue.sync { innerQueue }
  }

  /// Clears the delegate and delegate queue.
  public func clear() {
    workQueue.sync {
      innerDelegate = nil
      innerQueue = nil
    }
  }

  /// Sets the delegate and delegate queue.
  public func setDelegate(_ delegate: Delegate, queue: DispatchQueue = DispatchQueue(label: "Telegraph.Delegator.delegate")) {
    workQueue.sync {
      innerDelegate = delegate as AnyObject
      innerQueue = queue
    }
  }

  /// Calls the delegate asynchronously.
  public func async(_ block: @escaping (Delegate) -> Void) {
    workQueue.async { [weak self] in
      guard let me = self, let delegate = (me.innerDelegate as? Delegate), let queue = me.innerQueue else { return }
      queue.async { block(delegate) }
    }
  }

  /// Calls the delegate asynchronously.
  public func async<T: AnyObject>(weak arg: T, _ block: @escaping (T, Delegate) -> Void) {
    workQueue.async { [weak arg, weak self] in
      guard let arg = arg, let me = self, let delegate = (me.innerDelegate as? Delegate), let queue = me.innerQueue else { return }
      queue.async { block(arg, delegate) }
    }
  }

  /// Calls the delegate synchronously.
  /// Note! Do not call any of the Delegator's methods in the block.
  public func sync<T>(_ block: (Delegate) -> T) -> T? {
    return workQueue.sync {
      guard let delegate = innerDelegate as? Delegate else { return nil }
      return innerQueue?.sync { block(delegate) }
    }
  }
}
