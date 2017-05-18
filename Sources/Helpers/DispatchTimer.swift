//
//  DispatchTimer.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/23/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public class DispatchTimer {
  private let queue: DispatchQueue
  private let block: () -> Void
  private var workItem: DispatchWorkItem?

  init(queue: DispatchQueue, block: @escaping () -> Void) {
    self.queue = queue
    self.block = block
  }

  func start(afterSec: TimeInterval) {
    // Stop an existing timer
    stop()

    // Create a new cancellable work item
    var newWorkItem: DispatchWorkItem?
    newWorkItem = DispatchWorkItem { [weak self] in
      guard let item = newWorkItem, !item.isCancelled else { return }
      self?.block()
    }

    // Store the work item and schedule it
    workItem = newWorkItem!
    queue.asyncAfter(deadline: .now() + afterSec, execute: workItem!)
  }

  func stop() {
    workItem?.cancel()
    workItem = nil
  }
}
