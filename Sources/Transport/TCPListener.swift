//
//  TCPListener.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/17/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public protocol TCPListenerDelegate: class {
  func listener(_ listener: TCPListener, didAcceptSocket socket: TCPSocket)
}

public final class TCPListener: NSObject {
  private let socket: GCDAsyncSocket
  private let socketDelegateQueue: DispatchQueue

  public let tlsConfig: TLSConfig?
  public weak var delegate: TCPListenerDelegate?

  public init(tlsConfig: TLSConfig? = nil) {
    self.tlsConfig = tlsConfig

    socket = GCDAsyncSocket()
    socketDelegateQueue = DispatchQueue(label: "Telegraph.TCPListener.delegate")
    super.init()

    socket.setDelegate(self, delegateQueue: socketDelegateQueue)
  }

  public func accept(onPort port: UInt16) throws {
    try socket.accept(onPort: port)
  }

  public func accept(onInterface interface: String?, port: UInt16) throws {
    try socket.accept(onInterface: interface, port: port)
  }

  public func disconnect() {
    socket.disconnect()
  }

  public var port: UInt16 {
    return socket.localPort
  }
}

// MARK: TCPListener GCDAsyncSocketDelegate

extension TCPListener: GCDAsyncSocketDelegate {
  public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
    let socket = TCPSocket(wrapping: newSocket)

    // Is this a secure connection?
    if let tlsConfig = tlsConfig {
      socket.startTLS(config: tlsConfig)
    }

    delegate?.listener(self, didAcceptSocket: socket)
  }
}
