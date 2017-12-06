# Change Log
All notable changes to this project will be documented in this file.
Telegraph adheres to [Semantic Versioning](http://semver.org/).

## [0.13](https://github.com/Building42/Telegraph/releases/tag/0.13)
- Add automatic port selection (thanks [harrisg](https://github.com/harrisg))
- Update CocoaAsyncSocket to version 7.6.2

## [0.12](https://github.com/Building42/Telegraph/releases/tag/0.12)
- Add support for implicit HEAD requests on GET routes (see `implicitHeadRequests` in `HTTPRouteHandler`)
- Fix route HTTP method matching (e.g. a GET route shouldn't respond to PUT)

## [0.11](https://github.com/Building42/Telegraph/releases/tag/0.11)
- Fix compability warnings for Xcode 9.1 / Swift 4.0.2
- Fix WebSocket bitmask crash on Xcode 9.1 / Swift 4.0.2 / iOS 11.1

## [0.10](https://github.com/Building42/Telegraph/releases/tag/0.10)
- Convert to Swift 4
- Allow custom WebSocket protocol and other headers
- Fix WebSocket bitmask handling for empty payloads

## [0.9](https://github.com/Building42/Telegraph/releases/tag/0.9)
- Add support for iOS 8
- Fix exclusive access issues reported by Xcode in the `HTTPParser`
- Update CocoaPods to version 1.3.1

## [0.8.1](https://github.com/Building42/Telegraph/releases/tag/0.8.1)
- Set CocoaAsyncSocket to version 7.6.1
- Few new examples in the README (thanks [TomasHubelbauer](https://github.com/TomasHubelbauer))
- The dependency versions are now less strict. Useful if you are using an older version of CocoaAsyncSocket.

## [0.8.0](https://github.com/Building42/Telegraph/releases/tag/0.8.0)
- Prevent private key issues on locked devices, [kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly](https://developer.apple.com/documentation/security/ksecattraccessibleafterfirstunlockthisdeviceonly) is now default
- **Breaking:** `CertificateIdentity` initializers without passphrase are no longer available on MacOS (see [README](README.md))
- **Breaking:** `KeychainManager` lost a few helper functions. If you need a keychain library, check out [LockSmith](https://github.com/matthewpalmer/Locksmith).

## [0.7.0](https://github.com/Building42/Telegraph/releases/tag/0.7.0)
- Add the option to bind the server to a specific interface (thanks [didi25](https://github.com/didi25))

## [0.6.0](https://github.com/Building42/Telegraph/releases/tag/0.6.0)
- Improve websocket ping/pong by not masking empty payloads
- Fix Xcode 9 warnings
- **Breaking:** Removed [Delegator](https://github.com/Building42/Telegraph/blob/0.5.0/Sources/Helpers/Delegator.swift) helper, webSocketDelegator has become webSocketDelegate
- **Breaking:** `WebSocketMessage` masking key has moved to the `WebSocketParser`
- **Breaking:** `WebSocketMessage` generateMask signature has changed

## [0.5.0](https://github.com/Building42/Telegraph/releases/tag/0.5.0)
- Improve connection handling and thread safety of the WebSocket client
- Allow empty certificates list in TLSConfig (thanks [JulianEberius](https://github.com/JulianEberius))

## [0.4.1](https://github.com/Building42/Telegraph/releases/tag/0.4.1)
- Fix URI relative path function

## [0.4.0](https://github.com/Building42/Telegraph/releases/tag/0.4.0)
- Add serving static files (thanks [Daij-Djan](https://github.com/Daij-Djan))
- Add new route helpers
- Change Date header to RFC7231 format

## [0.3.0](https://github.com/Building42/Telegraph/releases/tag/0.3.0)
- Add macOS support
- Add Carthage support

## [0.2.0](https://github.com/Building42/Telegraph/releases/tag/0.2.0)
- Add tvOS support

## [0.1.0](https://github.com/Building42/Telegraph/releases/tag/0.1.0)
- First release
