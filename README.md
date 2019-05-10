![Telegraph: Secure Web Server for iOS, tvOS and macOS](https://github.com/Building42/Telegraph/raw/master/Resources/logo.png)

[![Build Status](https://travis-ci.org/Building42/Telegraph.svg?branch=master)](https://travis-ci.org/Building42/Telegraph)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/Telegraph.svg?style=flat)](https://cocoapods.org/pods/Telegraph)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Telegraph.svg?style=flat)](https://cocoapods.org/pods/Telegraph)
[![Platform](https://img.shields.io/cocoapods/p/Telegraph.svg?style=flat)](https://cocoapods.org/pods/Telegraph)

Telegraph is a Secure Web Server for iOS, tvOS and macOS written in Swift.

- [Features](#features)
- [Platforms](#platforms)
- [Versions](#versions)
- [Installation](#installation)
- [Build](#build)
- [Usage](#usage)
- [TODOs](#todos)
- [FAQ](#faq)
- [Authors](#authors)
- [License](#license)

## Features

- [x] Handles HTTP 1.0/1.1 requests
- [x] Secure traffic, HTTPS/TLS encryption
- [x] WebSocket client and server
- [x] Uses well tested socket library [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)
- [x] Uses performant, low memory, HTTP parser C library [http-parser](https://github.com/nodejs/http-parser)
- [x] Customizable, from time-outs to message handlers
- [x] Simple, well commented code

## Platforms

- iOS 8.0+
- tvOS 9.0+
- macOS 10.10+

## Versions

- Swift 5.0: [master branch](https://github.com/Building42/Telegraph/tree/master)
- Swift 4.2: [swift-4.2 branch](https://github.com/Building42/Telegraph/tree/swift-4.2)
- Swift 4.0: [swift-4 branch](https://github.com/Building42/Telegraph/tree/swift-4)
- Swift 3.0: [swift-3 branch](https://github.com/Building42/Telegraph/tree/swift-3)

## Installation

### Carthage

Carthage is a decentralized dependency manager that builds your dependencies into binary frameworks.

```ogdl
github "Building42/Telegraph"
```

See [Carthage - Quick Start](https://github.com/Carthage/Carthage/#quick-start) for more information.

### CocoaPods

CocoaPods is a dependency manager for Cocoa projects that makes dependencies a part of your workspace.

```ruby
target '<Your Target Name>'
use_frameworks!

pod 'Telegraph'
```

See [CocoaPods - Getting Started](https://guides.cocoapods.org/using/getting-started.html) for more information.

## Build

You can build the Telegraph framework and the examples with these steps:

1. install [Carthage](https://github.com/Carthage/Carthage) using Homebrew
2. clone the repository
3. run `carthage bootstrap`
4. open Telegraph.xcworkspace, select a scheme and build

This is only necessary if you want to make changes to the framework or try out the examples.

## Usage

### Configure App Transport Security

With iOS 9 Apple introduced APS (App Transport Security) in an effort to improve user security and privacy by requiring apps to use secure network connections over HTTPS. It means that without additional configuration unsecure HTTP requests in apps that target iOS 9 or higher will fail. In iOS 9, APS is unfortunately also activated for LAN connections. Apple fixed this in iOS 10, by adding `NSAllowsLocalNetworking`.

Even though we are using HTTPS, we have to consider the following:

1. when we are communicating between iPads, it is likely that we'll connect on IP addresses, or at least that the hostname of the device won't match the *common name* of the certificate.
2. our server will use a certificate signed by our own Certificate Authority instead of a well recognized root Certificate Authority.

You can disable APS by adding the key `App Transport Security Settings` to your Info.plist, with a sub-key where `Allow Arbitrary Loads` is set to `Yes`. For more information see [ATS Configuration Basics](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW35).

### Prepare the certificates

For a secure web server you'll need two things:

1. one or more Certificate Authority certificates in DER format.
2. a PKCS12 bundle containing a private key and certificate (signed by the CA)

Telegraph contains classes to make it easier to load the certificates:

```swift
let caCertificateURL = Bundle.main.url(forResource: "ca", withExtension: "der")!
let caCertificate = Certificate(derURL: caCertificateURL)!

let identityURL = Bundle.main.url(forResource: "localhost", withExtension: "p12")!
let identity = CertificateIdentity(p12URL: identityURL, passphrase: "test")!
```

> Note: macOS doesn't accept P12 files without passphrase.

### HTTP: Server

You most likely want to create a secure server by passing in the certificates:

```swift
serverHTTPs = Server(identity: identity, caCertificates: [caCertificate])
try! server.start(port: 9000)
```

Or for a quick test, create an unsecure server:

```swift
serverHTTP = Server()
try! server.start(port: 9000)
```

You can limit the server to localhost connections by specifying an interface when you start it:

```swift
try! server.start(port: 9000, interface: "localhost")
```

### HTTP: Routes

Routes consist of three parts: HTTP method, path and a handler:

```swift
server.route(.POST, "test", handleTest)
server.route(.GET, "hello/:name", handleGreeting)
server.route(.GET, "secret/*") { .forbidden }
server.route(.GET, "status") { (.ok, "Server is running") }

server.serveBundle(.main, "/")

// You can also serve custom urls, for example the Demo folder in your bundle
let demoBundleURL = Bundle.main.url(forResource: "Demo", withExtension: nil)!
server.serveDirectory(demoBundleURL, "/demo")
```

Slashes at the start of the path are optional. Routes are case insensitive. You can specify custom regular expressions for more advanced route matching. When none of the routes are matched, the server will return a 404 not found.

The first route in the example above has a route parameter (name). When the server matches the incoming request to that route it will place the parameter in the `params` array of the request:

```swift
func handleGreeting(request: HTTPRequest) -> HTTPResponse {
  let name = request.params["name"] ?? "stranger"
  return HTTPResponse(content: "Hello \(name.capitalized)")
}
```

### HTTP: Middleware

When a HTTP request is handled by the Server it is passed through a chain of message handlers. If you don't change the default configuration, requests will first be passed to the `HTTPWebSocketHandler` and then to the `HTTPRouteHandler`.

Below is an example of a message handler:

```swift
public class HTTPGETOnlyHandler: HTTPRequestHandler {
  public func respond(to request: HTTPRequest, nextHandler: HTTPRequest.Handler) throws -> HTTPResponse? {
    // If this is a GET request, pass it to the next handler
    if request.method == .GET {
      return try nextHandler(request)
    }

    // Otherwise return 403 - Forbidden
    return HTTPResponse(.forbidden, content: "Only GET requests are allowed")
  }
}
```

You can enable the message handler by setting it in the HTTP configuration:

```swift
server.httpConfig.requestHandlers.insert(HTTPGETOnlyHandler(), at: 0)
```

Note that the order of the request handlers is important. You'll probably want to have the `HTTPRouteHandler` as the last request handler or your Server won't handle any route requests. The `HTTPRouteHandler` doesn't call any handlers, so don't specify any handlers after the `HTTPRouteHandler`.

You can also modify the request in handlers. This handler copies the QueryString items into the request's `params` dictionary:

```swift
public class HTTPRequestParamsHandler: HTTPRequestHandler {
  public func respond(to request: HTTPRequest, nextHandler: HTTPRequest.Handler) throws -> HTTPResponse? {
    // Extract the query string items and put them in the HTTPRequest params
    request.uri.queryItems?.forEach { item in
      request.params[item.name] = item.value
    }

    // Continue with the rest of the handlers
    return try nextHandler(request)
  }
}
```

But what if you want to add headers to a response? Simply call the chain and modify the result:

```swift
public class HTTPAppDetailsHandler: HTTPRequestHandler {
  public func respond(to request: HTTPRequest, nextHandler: HTTPRequest.Handler) throws -> HTTPResponse? {
    //  Let the other handlers create a response
    let response = try nextHandler(request)

    // Add our own bit of magic
    response.headers["X-App-Version"] = "My App 1.0"
    return response
  }
}
```

### HTTP: Cross-Origin Resource Sharing (CORS)

The CORS mechanism controls which sites will have permission to access the resources of your server. You can set CORS by sending the `Access-Control-Allow-Origin` header to the client. For development purposes it can be useful to allow all sites with the `*` value.

```swift
response.headers["Access-Control-Allow-Origin"] = "*"
```

If you want to make it a bit fancier, you can create a handler:

```swift
public class HTTPCORSHandler: HTTPRequestHandler {
  public func respond(to request: HTTPRequest, nextHandler: HTTPRequest.Handler) throws -> HTTPResponse? {
    let response = try nextHandler(request)

    // Add access control header for GET requests
    if request.method == .GET {
      response?.headers["Access-Control-Allow-Origin"] = "*"
    }

    return response
  }
}
```

For increased security you can add additional checks, dig down into the request, and send back different CORS headers for different clients.

### HTTP: Client

For client connections we'll use Apple's [URLSession](https://developer.apple.com/reference/foundation/urlsession) class. Ray Wenderlich has an [excellent tutorial](https://www.raywenderlich.com/110458/nsurlsession-tutorial-getting-started) on it.
We're going to have to manually verify the TLS handshake (App Transport Security needs to be disabled for this):

```swift
let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
let tlsPolicy = TLSPolicy(commonName: "localhost", certificates: [caCertificate])

extension YourClass: URLSessionDelegate {
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    // The TLSPolicy class will do most of the work for us
    let credential = tlsPolicy.evaluateSession(trust: challenge.protectionSpace.serverTrust)
    completionHandler(credential == nil ? .cancelAuthenticationChallenge : .useCredential, credential)
  }
}
```

The common name in the `TLSPolicy` should match the common name of the certificate of the server (that was provided in the P12 archive). Although I don't recommend it, you can disable the common name check by providing an empty string (if you provide `nil`, the common name will be compared to the device's hostname).

For the common name you aren't limited to the hostname or IP address of the device. Your backend could, for example, generate a certificate with a common name that matches the UUID of the device. If the client knows the UUID of device it is connecting to, you could make it part of the `TLSPolicy` check.

### WebSockets: Server-side

Your Server will automatically recognize WebSocket requests, thanks to the `HTTPWebSocketHandler` that is by default in the list of HTTP request handlers. Set the WebSocket delegate to handle incoming messages:

```swift
server.webSocketDelegate = self
```

Next step is to implement the `ServerWebSocketDelegate` methods:

```swift
func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
  // A web socket connected, you can extract additional information from the handshake request
  webSocket.send(text: "Welcome!")
}

func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?) {
  // One of our web sockets disconnected
}

func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
  // One of our web sockets sent us a message
}

func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage) {
  // We sent one of our web sockets a message (often you won't need to implement this one)
}
```

### WebSockets: Middleware

Web sockets can have custom handlers too, although instead of a whole chain of handlers you specify a single class. The `WebSocketMessageDefaultHandler` will respond to connection-close messages and handle ping messages.

I recommend creating custom handlers by inheriting from the default handler:

```swift
public class AwesomeWebSocketHandler: WebSocketMessageHandler {
  public func incoming(message: WebSocketMessage, from webSocket: WebSocket) throws {
    // Don't forget to call super (for ping-pong etc.)
    super.incoming(message: message, from: webSocket)

    // Echo incoming text messages
    switch message.payload {
    case let .text(text): webSocket.send(text: text)
    default: break
    }
  }
}
```

### WebSockets: Client-side

Now that we have a secure WebSocket server, we can use a secure WebSocket client as well by passing the CA certificate. Note that you only have to specify the CA certificate if the certificate isn't a root CA trusted by Apple or if you want to benefit from [certificate pinning](https://security.stackexchange.com/questions/29988/what-is-certificate-pinning).

```swift
client = try! WebSocketClient("wss://localhost:9000", certificates: [caCertificate])
client.delegate = self

// You can specify headers too
client.headers.authorization = "Bearer secret-token"
```

The delegate methods look like this:

```swift
func webSocketClient(_ client: WebSocketClient, didConnectToHost host: String) {
  // The connection starts off as a HTTP request and then is upgraded to a
  // web socket connection. This method is called if the handshake was succesful.
}

func webSocketClient(_ client: WebSocketClient, didDisconnectWithError error: Error?) {
  // We were disconnected from the server
}

func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data) {
  // We received a binary message. Ping, pong and the other opcodes are handled for us.
}

func webSocketClient(_ client: WebSocketClient, didReceiveText text: String) {
  // We received a text message, let's send one back
  client.send(text: "Message received")
}
```

## FAQ

### Why Telegraph?

There are only a few web servers available for iOS and many of them don't have SSL support. Our main goal with Telegraph is to offer secure HTTP and Web Socket traffic between iPads. The name is a tribute to the electrical telegraph, the first form of electrical telecommunications.

### How do I create the certificates?

Basically what you want is a Certificate Authority and a Device certificate signed by that authority.
You can find a nice tutorial at: https://jamielinux.com/docs/openssl-certificate-authority/

### My server isn't working properly

Please check the following:

1. is Application Transport Security disabled?
2. are your certificates valid?
3. are your routes valid?
4. have you customized any handlers? Is the route handler still included?

Have a look at the example project in this repository for a working starting point.

### My browser doesn't display images from my bundle

During the build of your project Apple tries to optimize your images to reduce the size of your bundle. This optimization process sometimes causes the images to become unreadable by Chrome. Test your image url in Safari to double check if this is the case.

To solve this you can go to the property inspector in Xcode and change the type of the resource from `Default - PNG image` to `Data`. After that the build process won't optimize your file. I've also done this with `logo.png` in the example projects.

If you want to reduce the size of your images, I highly recommend [ImageOptim](https://imageoptim.com).

### Why can't I use port 80 and 443?

The first 1024 port numbers are restricted to root access only and your app doesn't have root access on the device. If you try to open a Server on those ports you will get a permission denied error when you start the server. For more information, read [why are the first 1024 ports restricted to the root user only](https://unix.stackexchange.com/questions/16564/why-are-the-first-1024-ports-restricted-to-the-root-user-only).

### What if the device goes on standby?

If your app is send to the background or if the device goes on standby you typically have about 3 minutes to handle requests and close connections.  You can create a background task with `UIApplication.beginBackgroundTask` to let iOS know that you need extra time to complete your operations. The property `UIApplication.shared.backgroundTimeRemaining` tells you the time that is left until a possible forced-kill of your app.

### What about HTTP/2 support?

Ever wondered how the remote server knows that your browser is HTTP/2 compatible? During TLS negotiation, the application-layer protocol negotiation (ALPN) extension field contains "h2" to signal that HTTP/2 is going be used. Apple doesn't offer any (public) methods in Secure Transport or CFNetwork to configure ALPN extensions. A secure HTTP/2 iOS implementation is therefor not possible at the moment.

### Can I use this in my Objective-C project?

This library was written in Swift and for performance reasons I haven't decorated classes with `NSObject` unless absolutely necessary (no dynamic dispatch). If you are willing to add Swift code to your project, you can integrate the server by adding a Swift wrapper class that inherits from `NSObject` and has a Telegraph `Server` variable.

## Authors

This library was created by:

- [Yvo van Beek](https://github.com/Zyphrax)
- [Bernd de Graaf](https://github.com/Vernadsky)

Code and design was inspired by:

- [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer) - a Web Server written in Objective-C
- [Vapor](https://github.com/vapor/vapor) - a Swift Web framework

Thank you to our contributors, your pull requests are most welcome and appreciated!

## License

Telegraph is released under the MIT license. See [LICENSE](https://github.com/Building42/Telegraph/blob/master/LICENSE) for details.
