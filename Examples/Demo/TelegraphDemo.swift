//
//  TelegraphDemo.swift
//  Telegraph Examples
//
//  Created by Yvo van Beek on 5/17/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Telegraph

class TelegraphDemo: NSObject {
  var identity: CertificateIdentity!
  var caCertificate: Certificate!

  var server: Server!

  var clientTLSPolicy: TLSPolicy!
  var webSocketClient: WebSocketClient!

  func start() {
    loadCertificates()
    setupServer()
    demoClientRequest()
    demoWebSocketConnect()
  }

  func loadCertificates() {
    // Load the P12 identity package from the bundle
    let identityURL = Bundle.main.url(forResource: "localhost", withExtension: "p12")!
    identity = CertificateIdentity(p12URL: identityURL, passphrase: "test")!

    // Load the Certificate Authority certificate from the bundle
    let caCertificateURL = Bundle.main.url(forResource: "ca", withExtension: "der")!
    caCertificate = Certificate(derURL: caCertificateURL)!

    // We want to override the default SSL handshake. We aren't using a trusted root
    // certificate authority and the hostname doesn't match the common name of the certificate.
    clientTLSPolicy = TLSPolicy(commonName: "localhost", certificates: [caCertificate])
  }

  func setupServer() {
    // Create a secure server
    server = Server(identity: identity, caCertificates: [caCertificate])
    server.webSocketConfig.pingInterval = 10
    server.webSocketDelegate = self

    // Define the demo routes
    server.route(.get, "hello/:name", serverHandleGreeting)
    server.route(.get, "hello(/)", serverHandleGreeting)
    server.route(.get, "secret/*") { .forbidden }
    server.route(.get, "status") { (.ok, "Server is running") }
    server.serveBundle(.main, "/")

    // Start the server on localhost, we'll skip error handling for the demo
    // Note: if you test in your browser, don't forget to type https://
    try! server.start()
    serverLog("Server is running at https://localhost:\(server.port)")
  }

  func demoClientRequest() {
    // Demonstrate a request on the /hello endpoint with (NS)URLSession
    // Note: we are setting ourself as the delegate to customize the SSL handshake
    let httpClient = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    let httpTask = httpClient.dataTask(with: URL(string: "https://localhost:\(server.port)/hello")!, completionHandler: clientHandleGreeting)
    httpTask.resume()
  }

  func demoWebSocketConnect() {
    // Demonstrate a WebSocket client connection
    webSocketClient = try! WebSocketClient("wss://localhost:\(server.port)", certificates: [caCertificate])
    webSocketClient.delegate = self
    webSocketClient.headers.webSocketProtocol = "myProtocol"
    webSocketClient.headers["X-Name"] = "Yvo"
    webSocketClient.connect()
  }
}

// MARK: - Route Handlers

extension TelegraphDemo {
  func serverHandleGreeting(request: HTTPRequest) -> HTTPResponse {
    let name = request.params["name"] ?? "stranger"
    return HTTPResponse(content: "Hello \(name.capitalized)")
  }
}

// MARK: - Client request Handlers

extension TelegraphDemo {
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

// MARK: - ServerWebSocketDelegate implementation

extension TelegraphDemo: ServerWebSocketDelegate {
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

extension TelegraphDemo: URLSessionDelegate {
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    // Use our custom TLS policy to verify if the server should be trusted
    let credential = clientTLSPolicy.evaluateSession(trust: challenge.protectionSpace.serverTrust)
    completionHandler(credential == nil ? .cancelAuthenticationChallenge : .useCredential, credential)
  }
}

// MARK: - WebSocketClientDelegate implementation

extension TelegraphDemo: WebSocketClientDelegate {
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

extension TelegraphDemo {
  func clientLog(_ message: String) {
    NSLog("[CLIENT] \(message)")
  }

  func serverLog(_ message: String) {
    NSLog("[SERVER] \(message)")
  }
}
