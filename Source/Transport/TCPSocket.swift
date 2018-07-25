//
//  TCPSocket.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/2/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

// MARK: TCPSocketError

public enum TCPSocketError: Error {
  case invalidHost
}

// MARK: TCPSocketClose

public enum TCPSocketClose {
  case immediately
  case afterReading
  case afterWriting
  case afterReadingAndWriting
}

// MARK: TCPSocketDelegate

public protocol TCPSocketDelegate: class {
  func socketDidOpen(_ socket: TCPSocket)
  func socketDidClose(_ socket: TCPSocket, wasOpen: Bool, error: Error?)
  func socketDidRead(_ socket: TCPSocket, data: Data)
  func socketDidWrite(_ socket: TCPSocket)
}

// MARK: TCPSocket

public final class TCPSocket: NSObject, ReadStream, WriteStream {
  public typealias ReadHandler = (Data) -> Void
  public typealias WriteHandler = () -> Void

  private let socketDelegateQueue: DispatchQueue
  private let socket: GCDAsyncSocket
  private var wasOpen = false

  public weak var delegate: TCPSocketDelegate?
  public var tlsPolicy: TLSPolicy?

  /// Initializes a new TCPSocket wrapping a GCDAsyncSocket.
  internal init(wrapping socket: GCDAsyncSocket) {
    self.socket = socket
    self.socketDelegateQueue = DispatchQueue(label: "Telegraph.TCPSocket.delegate")
    super.init()

    socket.setDelegate(self, delegateQueue: socketDelegateQueue)
  }

  /// Initializes a new TCPSocket.
  public convenience override init() {
    self.init(wrapping: GCDAsyncSocket())
  }

  /// Returns a boolean indicating if the socket is connected.
  public var isOpen: Bool {
    return socket.isConnected
  }

  /// Opens a connection to the host based on the provided url.
  public func open(toURL url: URL, timeout: TimeInterval) {
    open(toHost: url.host ?? "", port: url.port ?? url.portBasedOnScheme, timeout: timeout)
  }

  /// Opens a connection to the host on the provided port.
  public func open(toHost host: String, port: Int, timeout: TimeInterval) {
    do {
      guard !host.isEmpty else { throw TCPSocketError.invalidHost }
      try socket.connect(toHost: host, onPort: UInt16(port), withTimeout: timeout)
    } catch {
      delegate?.socketDidClose(self, wasOpen: false, error: error)
    }
  }

  /// Closes the connection.
  public func close(when: TCPSocketClose = .immediately) {
    switch when {
    case .immediately: socket.disconnect()
    case .afterReading: socket.disconnectAfterReading()
    case .afterWriting: socket.disconnectAfterWriting()
    case .afterReadingAndWriting: socket.disconnectAfterReadingAndWriting()
    }
  }

  /// Reads data with a maximum duration of timeout.
  public func read(timeout: TimeInterval) {
    socket.readData(withTimeout: timeout, tag: 0)
  }

  /// Writes data with a maximum duration of timeout.
  public func write(data: Data, timeout: TimeInterval) {
    socket.write(data, withTimeout: timeout, tag: 0)
  }

  /// Starts the TLS handshake for secure connections.
  public func startTLS(config: TLSConfig = TLSConfig()) {
    var rawConfig = config.rawConfig

    // When a TLS policy is set, enable manual trust evaluation
    if tlsPolicy != nil {
      rawConfig[GCDAsyncSocketManuallyEvaluateTrust] = true as CFBoolean
    }

    socket.startTLS(rawConfig)
  }
}

// MARK: GCDAsyncSocketDelegate implementation

extension TCPSocket: GCDAsyncSocketDelegate {
  public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
    wasOpen = true
    delegate?.socketDidOpen(self)
  }

  public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    delegate?.socketDidClose(self, wasOpen: wasOpen, error: err)
  }

  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    delegate?.socketDidRead(self, data: data)
  }

  public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
    delegate?.socketDidWrite(self)
  }

  public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
    // Evaluate the trust using the provided policy
    let trusted = tlsPolicy?.evaluate(trust: trust) ?? false
    completionHandler(trusted)
  }
}

// MARK: TCPSocketDelegate default implementations

extension TCPSocketDelegate {
  public func socketDidOpen(_ socket: TCPSocket) {}
  public func socketDidRead(_ socket: TCPSocket, data: Data) {}
  public func socketDidWrite(_ socket: TCPSocket) {}
}
