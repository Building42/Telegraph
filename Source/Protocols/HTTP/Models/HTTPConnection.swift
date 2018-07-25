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
  func connection(_ httpConnection: HTTPConnection, handleIncomingRequest request: HTTPRequest, error: Error?) -> HTTPResponse?
  func connection(_ httpConnection: HTTPConnection, handleIncomingResponse response: HTTPResponse, error: Error?)
  func connection(_ httpConnection: HTTPConnection, handleUpgradeTo protocolName: String, initiatedBy request: HTTPRequest) -> Bool
}

// MARK: HTTPConnection

public class HTTPConnection: TCPConnection, Hashable, Equatable {
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
  public func send(response: HTTPResponse) {
    response.prepareForWrite()
    response.write(to: socket, headerTimeout: config.writeHeaderTimeout, bodyTimeout: config.writeBodyTimeout)
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
    case is HTTPRequest:
      received(request: message as! HTTPRequest, error: error)
    case is HTTPResponse:
      received(response: message as! HTTPResponse, error: error)
    default:
      socket.close()
    }
  }

  /// Handles an incoming request.
  private func received(request: HTTPRequest, error: Error?) {
    var messageError = error

    // This server only supports HTTP/1.0 and HTTP/1.1
    if request.version.major != 1 && request.version.minor > 1 {
      messageError = messageError ?? HTTPError.invalidVersion
    }

    // Ask the delegate to handle the incoming request
    guard let response = delegate?.connection(self, handleIncomingRequest: request, error: error) else {
      socket.close()
      return
    }

    // Match the http version
    response.version = request.version

    // Do not write the body for HEAD requests
    if request.method == .head {
      response.stripBody = true
    }

    // Send the response
    send(response: response)

    // Should we upgrade the connection?
    if response.isConnectionUpgrade {
      let protocolName = response.headers.upgrade!.lowercased()
      if delegate?.connection(self, handleUpgradeTo: protocolName, initiatedBy: request) == true {
        upgrading = true
        return
      }

      // Invalid upgrade, close the connection
      response.closeAfterWrite = true
    }

    // Close the connection?
    if !request.keepAlive || response.closeAfterWrite {
      socket.close(when: .afterWriting)
    }
  }

  /// Handles an incoming response.
  private func received(response: HTTPResponse, error: Error?) {
    upgrading = response.isConnectionUpgrade
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

// MARK: HTTPConnectionDelegate default implementation

extension HTTPConnectionDelegate {
  public func connection(_ httpConnection: HTTPConnection, handleIncomingRequest request: HTTPRequest, error: Error?) -> HTTPResponse? { return nil }
  public func connection(_ httpConnection: HTTPConnection, handleIncomingResponse response: HTTPResponse, error: Error?) {}
  public func connection(_ httpConnection: HTTPConnection, handleUpgradeTo protocolName: String, initiatedBy request: HTTPRequest) -> Bool { return false }
}
