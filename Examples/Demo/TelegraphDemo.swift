//
//  TelegraphDemo.swift
//  Telegraph Examples
//
//  Created by Yvo van Beek on 5/17/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Telegraph

public class TelegraphDemo: NSObject {
  var identity: CertificateIdentity?
  var caCertificate: Certificate?
  var tlsPolicy: TLSPolicy?

  var server: Server!
  var webSocketClient: WebSocketClient!
}

extension TelegraphDemo {
  public func start() {
    // Comment out this line if you want HTTP instead of HTTPS
    loadCertificates()

    // Create and start the server
    setupServer()

    // Demonstrate client requests and web socket connection
    demoClientNormalRequest()
    demoClientJSONRequest()
    demoWebSocketConnect()
  }
}

extension TelegraphDemo {
  private func loadCertificates() {
    // Load the P12 identity package from the bundle
    if let identityURL = Bundle.main.url(forResource: "localhost", withExtension: "p12") {
      identity = CertificateIdentity(p12URL: identityURL, passphrase: "test")
    }

    // Load the Certificate Authority certificate from the bundle
    if let caCertificateURL = Bundle.main.url(forResource: "ca", withExtension: "der") {
      caCertificate = Certificate(derURL: caCertificateURL)
    }

    // We want to override the default SSL handshake. We aren't using a trusted root
    // certificate authority and the hostname doesn't match the common name of the certificate.
    if let caCertificate = caCertificate {
      tlsPolicy = TLSPolicy(commonName: "localhost", certificates: [caCertificate])
    }
  }

  private func setupServer() {
    // Create the server instance
    if let identity = identity, let caCertificate = caCertificate {
      server = Server(identity: identity, caCertificates: [caCertificate])
    } else {
      server = Server()
    }

    // Set a low web socket ping interval to demonstrate ping-pong
    server.webSocketConfig.pingInterval = 10
    server.webSocketDelegate = self

    // Define the demo routes
    // Note: we're ignoring possible strong retain cycles in the demo
    server.route(.get, "hello/:name", serverHandleHello)
    server.route(.get, "hello(/)", serverHandleHello)
    server.route(.get, "secret/*") { .forbidden }
    server.route(.get, "status") { (.ok, "Server is running") }

    server.route(.post, "data", serverHandleData)

    server.serveBundle(.main, "/")

    // Start the server on localhost
    // Note: we'll skip error handling in the demo
    try! server.start()

    // Log the url for easy access
    serverLog("Server is running at \(serverURL())")
  }

  private func serverURL(path: String = "") -> URL {
    /// Generate a server url, we'll assume the server has been started
    var components = URLComponents()
    components.scheme = server.isSecure ? "https" : "http"
    components.host = "localhost"
    components.port = Int(server.port)
    components.path = path
    return components.url!
  }
}

extension TelegraphDemo {
  private func demoClientNormalRequest() {
    // Demonstrate a request on the /hello endpoint
    let request = URLRequest(url: serverURL(path: "/hello"))
    performClientRequest(with: request, completionHandler: self.clientHandleHello)
  }

  private func demoClientJSONRequest() {
    // Prepare some JSON
    let content = ["name": "Yvo"]
    let jsonData = try! JSONSerialization.data(withJSONObject: content)

    // Demonstrate a JSON request on the /data endpoint
    var request = URLRequest(url: serverURL(path: "/data"))
    request.httpMethod = "POST"
    request.httpBody = jsonData
    performClientRequest(with: request, completionHandler: self.clientHandleData)
  }

  private func demoWebSocketConnect() {
    // Create the web socket client instance
    if let caCertificate = caCertificate {
      webSocketClient = try! WebSocketClient(url: serverURL(), certificates: [caCertificate])
    } else {
      webSocketClient = try! WebSocketClient(url: serverURL())
    }

    // We can define our own protocal and set custom headers
    webSocketClient.headers.webSocketProtocol = "myProtocol"
    webSocketClient.headers["X-Name"] = "Yvo"

    // Open the web socket connection
    webSocketClient.delegate = self
    webSocketClient.connect()
  }

  private func performClientRequest(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse) -> Void) {
    // Create a client session, we are setting ourself as the delegate to customize the SSL handshake
    let httpClient = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)

    // Create the request task, we'll centralize the request errors
    let httpTask = httpClient.dataTask(with: request) { data, response, error in
      // Did an error occur?
      guard error == nil else {
        self.clientLog("Request failed, error: \(error!)")
        return
      }

      // Call the handler
      completionHandler(data, response!)
    }

    // Perform the request
    httpTask.resume()
  }
}

// MARK: - Server route handlers

extension TelegraphDemo {
  private func serverHandleHello(request: HTTPRequest) -> HTTPResponse {
    // Raised when the /hello enpoint is called
    // Process the (optional) url parameters
    let name = request.params["name"] ?? "stranger"

    // Send a friendly text reponse
    return HTTPResponse(content: "Hello \(name.capitalized)")
  }

  private func serverHandleData(request: HTTPRequest) -> HTTPResponse {
    // Raised when the /data enpoint is called
    var name = "stranger"

    // Try to extract a name from the JSON data
    if let json = try? JSONSerialization.jsonObject(with: request.body),
       let content = json as? [String: Any], let jsonName = content["name"] as? String {
      name = jsonName
    }

    // Prepare the JSON response data
    let content = ["welcome": name]
    let jsonData = try! JSONSerialization.data(withJSONObject: content)

    // Send a JSON response
    return HTTPResponse(data: jsonData)
  }
}

// MARK: - Client request handlers

extension TelegraphDemo {
  private func clientHandleHello(data: Data?, response: URLResponse) {
    // Raised when the client processes the /hello endpoint response
    if let textData = data, let text = String(data: textData, encoding: .utf8) {
      clientLog("Request on /hello succeeded: \(text)")
    }
  }

  private func clientHandleData(data: Data?, response: URLResponse) {
    // Raised when the client processes the /data endpoint response
    if let jsonData = data, let json = try? JSONSerialization.jsonObject(with: jsonData) {
      clientLog("Request on /data succeded: \(json)")
    }
  }
}

// MARK: - ServerWebSocketDelegate implementation

extension TelegraphDemo: ServerWebSocketDelegate {
  public func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
    // Raised when a web socket client connects to the server
    let name = handshake.headers["X-Name"] ?? "stranger"
    serverLog("WebSocket connected (\(name))")
  }

  public func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?) {
    // Raised when a web socket client disconnects from the server
    if let error = error {
      serverLog("WebSocket disconnected, error: \(error)")
    } else {
      serverLog("WebSocket disconnected")
    }
  }

  public func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
    // Raised when the server receives a web socket message
    serverLog("WebSocket received message: \(message)")
  }

  public func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage) {
    // Raised when the server sends a web socket message
    serverLog("WebSocket sent message: \(message)")
  }

  public func serverDidDisconnect(_ server: Server) {
    // Raised when the server gets disconnected
    serverLog("Server disconnected")
  }
}

// MARK: - URLSessionDelegate implementation

extension TelegraphDemo: URLSessionDelegate {
  public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                         completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    // Use our custom TLS policy to verify if the server should be trusted
    let credential = tlsPolicy!.evaluateSession(trust: challenge.protectionSpace.serverTrust)
    completionHandler(credential == nil ? .cancelAuthenticationChallenge : .useCredential, credential)
  }
}

// MARK: - WebSocketClientDelegate implementation

extension TelegraphDemo: WebSocketClientDelegate {
  public func webSocketClient(_ client: WebSocketClient, didConnectToHost host: String) {
    // Raised when the web socket client has connected to the server
    clientLog("WebSocket connected to \(host)")

    server.webSockets.forEach { $0.send(text: "This is a text message") }
    server.webSockets.forEach { $0.send(data: Data(bytes: [0x00, 0x01, 0x02, 0x03, 0x04, 0x05])) }
  }

  public func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data) {
    // Raised when the web socket client received data
    clientLog("WebSocket received data: \(data as NSData)")
  }

  public func webSocketClient(_ client: WebSocketClient, didReceiveText text: String) {
    // Raised when the web socket client received text
    clientLog("WebSocket received text: \(text)")
  }

  public func webSocketClient(_ client: WebSocketClient, didDisconnectWithError error: Error?) {
    // Raised when the web socket client disconnects. Provides an error if the disconnect was unexpected.
    if let error = error {
      clientLog("WebSocket disconnected, error: \(error)")
    } else {
      clientLog("WebSocket disconnected")
    }
  }
}

// MARK: Logging helpers

extension TelegraphDemo {
  private func serverLog(_ message: String) {
    print("[SERVER] \(message)")
  }

  private func clientLog(_ message: String) {
    print("[CLIENT] \(message)")
  }
}
