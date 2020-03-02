//
//  ServerTests.swift
//  Telegraph Tests
//
//  Created by Yvo van Beek on 3/1/20.
//  Copyright © 2020 Building42. All rights reserved.
//

import XCTest
@testable import Telegraph

@objc class ServerTests: XCTestCase {
  private var server: Server!
  private var client: URLSession!
  private var tlsHandler: TLSHandler?

  /// Tests a request to an unsecure (HTTP) server.
  func testServerUnsecure() {
    server = Server()
    performTestRequest()
  }

  /// Tests a request to a secure (HTTPS) server.
  func testServerSecure() {
    let identityURL = Bundle.main.url(forResource: "localhost", withExtension: "p12")
    let identity = CertificateIdentity(p12URL: identityURL!, passphrase: "test")!
    let caCertificateURL = Bundle.main.url(forResource: "ca", withExtension: "der")
    let caCertificate = Certificate(derURL: caCertificateURL!)!
    let tlsPolicy = TLSPolicy(commonName: "localhost", certificates: [caCertificate])

    tlsHandler = TLSHandler(tlsPolicy: tlsPolicy)

    server = Server(identity: identity, caCertificates: [caCertificate])
    performTestRequest()
  }

  private func performTestRequest() {
    let test = expectation(description: "Server responds to request")

    let endpoint = "/status"
    let endpointResponse = (status: HTTPStatus.ok, text: "Server is running")

    // Configure and start the server
    server.route(.GET, endpoint) { endpointResponse }
    try! server.start(interface: "localhost")

    // Initialize the client
    client = URLSession(configuration: .ephemeral, delegate: tlsHandler, delegateQueue: .main)

    // Prepare the request
    let url = server.url(path: endpoint)
    let request = URLRequest(url: url)

    // Perform the request
    let task = client.dataTask(with: request) { data, response, error in
      XCTAssertNil(error, "Request error")
      XCTAssertNotNil(data, "Response data null")

      if let httpResponse = response as? HTTPURLResponse {
        XCTAssertEqual(httpResponse.statusCode, endpointResponse.status.code, "Response status invalid")

        if let text = String(data: data!, encoding: .utf8) {
          XCTAssertEqual(text, text, endpointResponse.text)
        }
      }

      test.fulfill()
    }

    task.resume()

    // Wait for the request to complete
    waitForExpectations(timeout: 2)
  }
}

class TLSHandler: NSObject, URLSessionDelegate {
  private let tlsPolicy: TLSPolicy

  /// Creates a TLSHandler.
  init(tlsPolicy: TLSPolicy) {
    self.tlsPolicy = tlsPolicy
  }

  /// Raised when the url session receives an authentication challenge. We'll use our custom TLS policy to verify if the server should be trusted.
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let credential = tlsPolicy.evaluateSession(trust: challenge.protectionSpace.serverTrust)
    completionHandler(credential == nil ? .cancelAuthenticationChallenge : .useCredential, credential)
  }
}

extension Server {
  /// Creates a url that points to this server.
  func url(host: String = "localhost", path: String) -> URL {
    var components = URLComponents()
    components.scheme = isSecure ? "https" : "http"
    components.host = host
    components.port = Int(port)
    components.path = path
    return components.url!
  }
}
