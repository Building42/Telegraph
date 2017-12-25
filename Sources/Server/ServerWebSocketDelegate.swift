//
//  ServerWebSocketDelegate.swift
//  Telegraph
//
//  Created by Yvo van Beek on 4/5/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public protocol ServerWebSocketDelegate: class {
  /// Called when a web socket connected
  func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest)

  /// Called when a web socket disconnected
  func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?)

  /// Called when a message was received from a web socket
  func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage)

  /// Called when a message was sent to a web socket
  func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage)

  /// Called when the server's listener has disconnected, this should result in the server completely disconnecting
  func serverDidDisconnect(_ server: Server)
}

// MARK: Default implementation

extension ServerWebSocketDelegate {
  func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {}
  func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage) {}
}
