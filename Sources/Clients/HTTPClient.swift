//
//  HTTPClient.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/16/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

internal class HTTPClient {
  internal typealias Handler = (HTTPResponse, Error?) -> Void
  private typealias Task = (HTTPRequest, Handler)

  private var connection: HTTPConnection?
  private var currentTask: Task?
  private var tasks = [Task]()

  internal lazy var socket = TCPSocket()
  internal let baseURL: URL
  internal var connectTimeout: TimeInterval = 10

  /// Initializes a new HTTPClient.
  internal init(baseURL: URL) {
    self.baseURL = baseURL
  }

  /// Creates a request and enqueues it.
  internal func request(method: HTTPMethod = .get, uri: URI, handler: @escaping Handler) {
    let request = HTTPRequest(method, uri: uri)
    tasks.append((request, handler))
    processNextTask()
  }

  /// Enqueues a request to the host.
  internal func request(_ request: HTTPRequest, handler: @escaping Handler) {
    tasks.append((request, handler))
    processNextTask()
  }

  /// Dequeues the next request.
  private func processNextTask() {
    // Check that we aren't busy or that the queue is empty
    guard currentTask == nil && !tasks.isEmpty else { return }
    currentTask = tasks.removeFirst()

    // Connect if necessary and wait for the callback
    if !socket.isOpen {
      socket.delegate = self
      socket.open(toURL: baseURL, timeout: connectTimeout)
      return
    }

    performCurrentTask()
  }

  /// Sends the dequeued request.
  private func performCurrentTask() {
    if let (request, _) = currentTask {
      connection?.send(request: request)
    }
  }

  /// Finishes the current request.
  private func finishCurrentTask(response: HTTPResponse?, error: Error?) {
    if let (_, handler) = currentTask {
      currentTask = nil
      handler(response ?? HTTPResponse(), error)
    }

    processNextTask()
  }
}

// MARK: Client properties

extension HTTPClient {
  internal var tlsPolicy: TLSPolicy? {
    get { return socket.tlsPolicy }
    set { socket.tlsPolicy = newValue }
  }
}

// MARK: TCPSocketDelegate implementation

extension HTTPClient: TCPSocketDelegate {
  public func socketDidOpen(_ socket: TCPSocket) {
  // Do we want a secure connection? Start TLS
    if baseURL.isSchemeSecure {
      socket.startTLS()
    }

    // Create a http connection
    connection = HTTPConnection(socket: socket, config: HTTPConfig.clientDefault)
    connection!.delegate = self
    connection!.open()

    performCurrentTask()
  }

  public func socketDidClose(_ socket: TCPSocket, wasOpen: Bool, error: Error?) {
    finishCurrentTask(response: nil, error: error)
  }
}

// MARK: HTTPConnectionDelegate implementation

extension HTTPClient: HTTPConnectionDelegate {
  public func connection(_ httpConnection: HTTPConnection, didCloseWithError error: Error?) {
    finishCurrentTask(response: nil, error: error)
  }

  public func connection(_ httpConnection: HTTPConnection, handleIncomingResponse response: HTTPResponse, error: Error?) {
    finishCurrentTask(response: response, error: error)
  }
}
