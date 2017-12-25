//
//  ServerWebSocketDelegate.swift
//  Telegraph
//
//  Created by Yvo van Beek on 4/5/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public protocol ServerWebSocketDelegate: class {
  func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest)
  func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?)

  func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage)
  func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage)
  
  /// Called when the main listener for the server has disconnected, this should result in the server completely disconnecting
  func serverDidDisconnect(_ server: Server)
}

// MARK: Default implementation

extension ServerWebSocketDelegate {
  func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {}
  func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage) {}
}
