//
//  HTTPFileHandler.swift
//  Telegraph
//
//  Created by Yvo van Beek on 5/16/17.
//  Copyright © 2017 Building42. All rights reserved.
//
//

import Foundation

open class HTTPFileHandler: HTTPRequestHandler {
  public private(set) var directoryURL: URL
  public private(set) var baseURI: URI
  public private(set) var index: String?

  /// Creates a HTTPFileHandler to serve the provided directory at the provided URI.
  public init(directoryURL: URL, baseURI: URI = .root, index: String? = "index.html") {
    self.directoryURL = directoryURL
    self.baseURI = baseURI
    self.index = index
  }

  /// Creates a response to the provided request or passes it to the next handler.
  open func respond(to request: HTTPRequest, nextHandler: HTTPRequest.Handler) throws -> HTTPResponse? {
    // Only respond to GET requests targetted at our path
    guard request.method == .GET, let relativePath = request.uri.relativePath(from: baseURI.path) else {
      return try nextHandler(request)
    }

    // Serve the requested URL
    let fileURL = directoryURL.appendingPathComponent(relativePath)
    return try responseForURL(fileURL)
  }

  /// Creates a response that serves the provided URL.
  private func responseForURL(_ url: URL) throws -> HTTPResponse {
    let fileManager = FileManager.default

    // Check if the requested path exists
    guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) as NSDictionary else {
      return HTTPResponse(.notFound)
    }

    // Determine the type of the requested resource
    guard let rawResourceType = attributes.fileType() else { return HTTPResponse(.forbidden) }
    let resourceType = FileAttributeType(rawValue: rawResourceType)

    // Allow directories
    if resourceType == .typeDirectory {
      guard let index = index else { return HTTPResponse(.forbidden) }

      // Create a response based on the index file in the directory
      let indexURL = url.appendingPathComponent(index, isDirectory: false)
      return try responseForURL(indexURL)
    }

    // Only provide the data of files and symbolic links
    guard resourceType == .typeRegular || resourceType == .typeSymbolicLink else {
      return HTTPResponse(.forbidden)
    }

    // Construct a response
    let response = HTTPResponse(.ok, body: try Data(contentsOf: url))
    response.headers.contentType = fileManager.mimeType(of: url)
    response.headers.lastModified = attributes.fileModificationDate()?.rfc1123

    return response
  }
}
