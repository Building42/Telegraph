//
//  DispatchTimer.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/23/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public class DispatchTimer {
  private let interval: TimeInterval
  private let queue: DispatchQueue
  private let block: () -> Void

  private var timer: DispatchSourceTimer?

  /// Initializes a DispatchTimer.
  public init(interval: TimeInterval = 0, queue: DispatchQueue = .global(qos: .background), execute block: @escaping () -> Void) {
    self.interval = interval
    self.queue = queue
    self.block = block
  }

  /// (Re)starts the timer, next run is immediately, after the interval or at a specific date.
  public func start(at startAt: Date? = nil) {
    stop()

    // Create a new timer
    timer = DispatchSource.makeTimerSource(queue: queue)
    timer?.setEventHandler(handler: block)

    // Schedule the timer to start at a specific time or after the interval
    let startDate = startAt ?? Date().addingTimeInterval(interval)
    let deadline = DispatchWallTime(date: startDate)

    if interval > 0 {
      timer?.schedule(wallDeadline: deadline, repeating: interval)
    } else {
      timer?.schedule(wallDeadline: deadline)
    }

    // Activate the timer
    timer?.resume()
  }

  /// (Re)starts the timer, next run will be after the specified interval.
  public func start(after: TimeInterval) {
    start(at: Date().addingTimeInterval(after))
  }

  /// Stops the timer.
  public func stop() {
    timer?.cancel()
    timer = nil
  }
}

// MARK: DispatchTimer convenience methods

extension DispatchTimer {
  /// Creates and starts a timer that runs multiple times with a specific interval.
  public static func run(interval: TimeInterval, queue: DispatchQueue = .global(qos: .background), execute block: @escaping () -> Void) -> DispatchTimer {
    let timer = DispatchTimer(interval: interval, queue: queue, execute: block)
    timer.start()
    return timer
  }

  /// Creates and starts a timer that runs at a specfic data, optionally repeating with a specific interval.
  public static func run(at: Date, interval: TimeInterval = 0, queue: DispatchQueue = .global(qos: .background), execute block: @escaping () -> Void) -> DispatchTimer {
    let timer = DispatchTimer(interval: interval, queue: queue, execute: block)
    timer.start(at: at)
    return timer
  }

  /// Creates and starts a timer that runs after a while, optionally repeating with a specific interval.
  public static func run(after: TimeInterval, interval: TimeInterval = 0, queue: DispatchQueue = .global(qos: .background), execute block: @escaping () -> Void) -> DispatchTimer {
    let timer = DispatchTimer(interval: interval, queue: queue, execute: block)
    timer.start(after: after)
    return timer
  }
}

// MARK: DispatchWallTime convenience initializers

extension DispatchWallTime {
  /// Initializes a DispatchWallTime with a date.
  public init(date: Date) {
    let (seconds, frac) = modf(date.timeIntervalSince1970)
    let wallTime = timespec(tv_sec: Int(seconds), tv_nsec: Int(frac * Double(NSEC_PER_SEC)))
    self.init(timespec: wallTime)
  }
}
