HTTP Parser
===========

[![Build Status](https://travis-ci.org/Building42/HTTPParserC.svg?branch=master)](https://travis-ci.org/Building42/HTTPParserC)
[![Version](https://img.shields.io/cocoapods/v/HTTPParserC.svg)](https://cocoapods.org/pods/HTTPParserC)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/HTTPParserC.svg)](https://cocoapods.org/pods/HTTPParserC)
[![Platform](https://img.shields.io/cocoapods/p/HTTPParserC.svg)](https://cocoapods.org/pods/HTTPParserC)

HTTP message parser written in C. It parses both requests and
responses. The parser is designed to be used in performance HTTP
applications. It does not make any syscalls nor allocations, it does not
buffer data, it can be interrupted at anytime. Depending on your
architecture, it only requires about 40 bytes of data per message
stream (in a web server that is per connection).

Features:

  * No dependencies
  * Handles persistent streams (keep-alive).
  * Decodes chunked encoding.
  * Upgrade support
  * Defends against buffer overflow attacks.

The parser extracts the following information from HTTP messages:

  * Header fields and values
  * Content-Length
  * Request method
  * Response status code
  * Transfer-Encoding
  * HTTP version
  * Request URL
  * Message body

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate the HTTP Parser C library into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
use_frameworks!
pod 'Telegraph'
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate HTTPParserC into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "Building42/HTTPParserC"
```

Run `carthage update` to build the framework and drag the built `HTTPParserC.framework` into your Xcode project.

## Documentation
Visit https://github.com/nodejs/http-parser for more information
