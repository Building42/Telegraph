//
//  FileManager+Ext.swift
//  Telegraph
//
//  Created by Yvo van Beek on 5/16/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
  import MobileCoreServices
#endif

public extension FileManager {
  /// Returns the mime type of a file.
  func mimeType(of url: URL) -> String {
    let fallback = "application/octet-stream"
    let fileExt = url.pathExtension as CFString

    guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExt, nil)?.takeRetainedValue() else { return fallback }
    guard let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() else { return fallback }
    return mimeType as String
  }
}
