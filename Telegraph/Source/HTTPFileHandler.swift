//
//  HTTPFileHandler.swift
//  Telegraph
//
//  Created by Dominik Pich on 5/14/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

public class HTTPFileHandler: HTTPRequestHandler {
    let folderURL: URL
    let baseURI: String
    let indexFile: String
    
    public init(_ folderURL: URL = Bundle.main.resourceURL!, baseURI: String = "", indexFile: String = "index.html") {
        self.folderURL = folderURL
        self.baseURI = baseURI
        self.indexFile = indexFile
    }
    
    open func respond(to request: HTTPRequest, nextHandler: HTTPRequest.Handler) throws -> HTTPResponse? {
        // If this is not a GET request or not in our documentRoot, pass it to the next handler
        guard request.method == .get && request.uri.string?.hasPrefix(baseURI) ?? false else {
            return try nextHandler(request)
        }
        
        //build the path
        let rest = request.uri.string?.replacingOccurrences(of: baseURI, with: "") ?? ""
        var url = folderURL.appendingPathComponent(rest);
        
        //check if a folder was requested
        var isDir : ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory:&isDir)
        if exists && isDir.boolValue {
            //append an index
            url = url.appendingPathComponent(indexFile)
        }
        
        //return response
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                //for really big data (Serveral hundred MB) this is an issue but for an embedded server that seems ok ;)
                let data = try Data(contentsOf: url)
                return HTTPResponse(.ok, data: data)
            }
            catch _ {
                #if DEBUG
                    return HTTPResponse(.internalServerError, content: "Cant read local file: \(url)")
                #else
                    return HTTPResponse(.internalServerError, content: "Cant read local file")
                #endif
            }
        }
        else {
            #if DEBUG
                return HTTPResponse(.notFound, content: "Local file doesn't exist @ \(url)")
            #else
                return HTTPResponse(.notFound, content: "Local file doesn't exist")
            #endif
        }
    }
}
