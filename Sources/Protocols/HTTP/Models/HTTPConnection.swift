//
//  HTTPConnection.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/2/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

// MARK: HTTPConnectionDelegate

public protocol HTTPConnectionDelegate: class {
  func connection(_ httpConnection: HTTPConnection, didCloseWithError error: Error?)
  func connection(_ httpConnection: HTTPConnection, handleIncomingRequest request: HTTPRequest, error: Error?)
  func connection(_ httpConnection: HTTPConnection, handleIncomingResponse response: HTTPResponse, error: Error?)
  func connection(_ httpConnection: HTTPConnection, handleUpgradeByRequest request: HTTPRequest)
}

// MARK: HTTPConnection

public class HTTPConnection: TCPConnection {
  public weak var delegate: HTTPConnectionDelegate?

  internal let socket: TCPSocket
  private let config: HTTPConfig
  private var parser: HTTPParser
  private var upgrading = false

  /// Initializes the HTTP connection.
  public required init(socket: TCPSocket, config: HTTPConfig) {
    self.socket = socket
    self.config = config
    self.parser = HTTPParser()
    self.parser.delegate = self
  }

  /// Opens the connection.
  public func open() {
    socket.delegate = self
    socket.read(timeout: config.readTimeout)
  }

  /// Closes the connection.
  public func close(immediately: Bool) {
    socket.close(when: immediately ? .immediately : .afterWriting)
  }

  /// Sends the request by writing it to the stream.
  public func send(request: HTTPRequest) {
    request.prepareForWrite()
    request.write(to: socket, headerTimeout: config.writeHeaderTimeout, bodyTimeout: config.writeBodyTimeout)
  }

  /// Sends the response by writing it to the stream.
  public func send(response: HTTPResponse, toRequest request: HTTPRequest) {
    // No response? Close the connection
    if response.status == .noResponse {
      close(immediately: true)
      return
    }

    // Do not write the body for HEAD requests
    if request.method == .HEAD {
      response.stripBody = true
    }

    // Do not keep-alive if the request doesn't want keep-alive
    if request.keepAlive == false {
      response.headers.connection = "close"
    }

    // Prepare and send the response
    response.prepareForWrite()
    response.write(to: socket, headerTimeout: config.writeHeaderTimeout, bodyTimeout: config.writeBodyTimeout)

    // Does the response request a connection upgrade?
    if response.isConnectionUpgrade {
      upgrading = true
      delegate?.connection(self, handleUpgradeByRequest: request)
      return
    }

    // Close the connection after writing if not keep-alive
    if !response.keepAlive {
      close(immediately: false)
    }
  }

  /// Handles incoming data.
  private func received(data: Data) {
    do {
      try parser.parse(data: data)
      if !upgrading { socket.read(timeout: config.readTimeout) }
    } catch {
      received(message: parser.message, error: error)
    }
  }

  /// Handles an incoming HTTP message.
  private func received(message: HTTPMessage?, error: Error?) {
    switch message {
    case let message as HTTPRequest:
      received(request: message, error: error)
    case let message as HTTPResponse:
      received(response: message, error: error)
    default:
      close(immediately: true)
    }
  }

  /// Handles an incoming request.
  private func received(request: HTTPRequest, error: Error?) {
    var messageError = error

    // This connection only supports HTTP/1.0 and HTTP/1.1
    if request.version.major != 1 && request.version.minor > 1 {
      messageError = messageError ?? HTTPError.invalidVersion
    }

    // Let our delegate handle the request
    delegate?.connection(self, handleIncomingRequest: request, error: error)
  }

  /// Handles an incoming response.
  private func received(response: HTTPResponse, error: Error?) {
    if response.isConnectionUpgrade { upgrading = true }
    delegate?.connection(self, handleIncomingResponse: response, error: error)
  }
}

// MARK: TCPSocketDelegate implementation

extension HTTPConnection: TCPSocketDelegate {
  public func socketDidRead(_ socket: TCPSocket, data: Data) {
    received(data: data)
  }

  public func socketDidClose(_ socket: TCPSocket, wasOpen: Bool, error: Error?) {
    parser.delegate = nil
    delegate?.connection(self, didCloseWithError: error)
  }
}

// MARK: HTTPParserDelegate implementation

extension HTTPConnection: HTTPParserDelegate {
  public func parser(_ parser: HTTPParser, didCompleteMessage message: HTTPMessage) {
    received(message: message, error: nil)
  }
}
