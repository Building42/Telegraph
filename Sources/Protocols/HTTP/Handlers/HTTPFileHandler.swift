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

  public init(directoryURL: URL, baseURI: URI = URI(), index: String? = "index.html") {
    self.directoryURL = directoryURL
    self.baseURI = baseURI
    self.index = index
  }

  open func respond(to request: HTTPRequest, nextHandler: HTTPRequest.Handler) throws -> HTTPResponse? {
    // Only respond to GET requests
    guard request.method == .get, let relativePath = request.uri.relativePath(from: baseURI.path) else {
      return try nextHandler(request)
    }

    // Determine the file to serve
    let fileManager = FileManager.default
    var fileURL = directoryURL.appendingPathComponent(relativePath)

    // Check if the requested path exists
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
      return HTTPResponse(.notFound)
    }

    // Is a directory requested?
    if isDirectory.boolValue {
      if let index = index {
        fileURL = fileURL.appendingPathComponent(index)

        // Make sure the index exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
          return HTTPResponse(.notFound)
        }
      } else {
        // No index? Forbidden
        return HTTPResponse(.forbidden)
      }
    }

    // Get the file information
    let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
    let contentType = fileManager.mimeType(of: fileURL)

    // Construct a response
    let response = HTTPResponse(.ok)
    response.headers.contentType = contentType
    response.body = try Data(contentsOf: fileURL)

    // Set the last modified date
    if let lastModified = fileAttributes[.modificationDate] as? Date {
      response.headers.lastModified = HTTPResponse.dateFormatter.string(from: lastModified)
    }

    return response
  }
}
