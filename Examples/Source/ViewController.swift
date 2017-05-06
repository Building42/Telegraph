//
//  ViewController.swift
//  iOS Example
//
//  Created by Yvo van Beek on 1/20/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import UIKit
import Telegraph

class ViewController: UIViewController {
  var server: Server!
  var tlsPolicy: TLSPolicy!
  var webSocketClient: WebSocketClient!

  override func viewDidLoad() {
    super.viewDidLoad()

    runDemo()
  }
}

// MARK: Demo

extension ViewController {
  func runDemo() {
    // Prepare the certificates
    let identityURL = Bundle.main.url(forResource: "localhost", withExtension: "p12")!
    let identity = CertificateIdentity(p12URL: identityURL)!

    let caCertificateURL = Bundle.main.url(forResource: "ca", withExtension: "der")!
    let caCertificate = Certificate(derURL: caCertificateURL)!

    // Create a server
    server = Server(identity: identity, caCertificates: [caCertificate])
    server.webSocketDelegator.setDelegate(self)

    // Define the routes
    server.route(.get, "hello/:name", serverHandleGreeting)
    server.route(.get, "hello(/)", serverHandleGreeting)
    server.route(.get, "/") { HTTPResponse(.ok, content: "Server is running") }

    // Start the server
    try! server.start(onPort: 9000)
    serverLog("Server is running at https://localhost:9000")

    // Define the TLS policy
    tlsPolicy = TLSPolicy(commonName: "localhost", certificates: [caCertificate])

    // Perform a request
    let httpClient = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    let httpTask = httpClient.dataTask(with: URL(string: "https://localhost:9000/hello")!, completionHandler: clientHandleGreeting)
    httpTask.resume()

    // Create the WebSocket client
    webSocketClient = try! WebSocketClient("wss://localhost:9000", certificates: [caCertificate])
    webSocketClient.delegate = self
    webSocketClient.headers["X-Name"] = "Yvo"

    // Connect the WebSocket client
    webSocketClient.connect()
  }
}

// MARK: - Client Handlers

extension ViewController {
  func clientHandleGreeting(data: Data?, response: URLResponse?, error: Error?) {
    if let textData = data, let text = String(data: textData, encoding: .utf8) {
      clientLog("Request succeeded: \(text)")
      return
    }

    if let error = error {
      clientLog("Request failed, error: \(error)")
    } else {
      clientLog("Request failed")
    }
  }
}

// MARK: - Route Handlers

extension ViewController {
  func serverHandleGreeting(request: HTTPRequest) -> HTTPResponse {
    let name = request.params["name"] ?? "stranger"
    return HTTPResponse(content: "Hello \(name.capitalized)")
  }
}

// MARK: - ServerWebSocketDelegate implementation

extension ViewController: ServerWebSocketDelegate {
  func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
    let name = handshake.headers["X-Name"] ?? "stranger"
    serverLog("WebSocket connected (\(name))")
  }

  func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?) {
    if let error = error {
      serverLog("WebSocket disconnected, error: \(error)")
    } else {
      serverLog("WebSocket disconnected")
    }
  }

  func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
    serverLog("WebSocket received message: \(message)")
  }

  func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage) {
    serverLog("WebSocket sent message: \(message)")
  }
}

// MARK: - URLSessionDelegate implementation

extension ViewController: URLSessionDelegate {
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let credential = tlsPolicy.evaluateSession(trust: challenge.protectionSpace.serverTrust)
    completionHandler(credential == nil ? .cancelAuthenticationChallenge : .useCredential, credential)
  }
}

// MARK: - WebSocketClientDelegate implementation

extension ViewController: WebSocketClientDelegate {
  func webSocketClient(_ client: WebSocketClient, didConnectToHost host: String) {
    clientLog("WebSocket connected to \(host)")

    server.webSockets.forEach { $0.send(text: "This is a text message") }
    server.webSockets.forEach { $0.send(data: Data(bytes: [0x00, 0x01, 0x02, 0x03, 0x04, 0x05])) }
  }

  func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data) {
    clientLog("WebSocket received data: \(data as NSData)")
  }

  func webSocketClient(_ client: WebSocketClient, didReceiveText text: String) {
    clientLog("WebSocket received text: \(text)")
  }

  func webSocketClient(_ client: WebSocketClient, didDisconnectWithError error: Error?) {
    if let error = error {
      clientLog("WebSocket disconnected, error: \(error)")
    } else {
      clientLog("WebSocket disconnected")
    }
  }
}

// MARK: Logging helpers

extension ViewController {
  func clientLog(_ message: String) {
    NSLog("[CLIENT] \(message)")
  }

  func serverLog(_ message: String) {
    NSLog("[SERVER] \(message)")
  }
}
