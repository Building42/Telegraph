//
//  CertificateIdentity.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/26/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

open class CertificateIdentity: RawRepresentable {
  public let rawValue: SecIdentity

  public required init(rawValue: SecIdentity) {
    self.rawValue = rawValue
  }

  public convenience init?(p12Data: Data, passphrase: String = "") {
    let options: [NSString: AnyObject] = [
      kSecImportExportPassphrase: passphrase as NSString
    ]

    // Import the PKCS12 file, this is the only way on iOS to create a SecIdentity
    var result: CFArray?
    let status = SecPKCS12Import(p12Data as NSData, options as CFDictionary, &result)
    guard status == errSecSuccess else { return nil }

    // The result is an array of dictionaries, we are looking for the one that contains the identity
    let resultArray = result as? [[NSString: AnyObject]]
    let resultIdentity = resultArray?.flatMap { dict in dict[kSecImportItemIdentity as NSString] }.first

    // Let's double check that we have a result and that it is a SecIdentity
    guard let rawValue = resultIdentity, CFGetTypeID(rawValue) == SecIdentityGetTypeID() else { return nil }
    self.init(rawValue: rawValue as! SecIdentity)
  }

  public convenience init?(p12URL: URL, passphrase: String = "") {
    guard let data = try? Data(contentsOf: p12URL) else { return nil }
    self.init(p12Data: data, passphrase: passphrase)
  }
}

// MARK: Keychain helpers

extension CertificateIdentity {
  public convenience init(fromKeychain label: String) throws {
    let rawValue = try KeychainManager.shared.find(identityWithLabel: label)
    self.init(rawValue: rawValue)
  }

  public func addToKeychain(label: String) throws {
    try KeychainManager.shared.add(identity: rawValue, label: label)
  }

  public static func removeFromKeychain(label: String) throws {
    try KeychainManager.shared.remove(identityWithLabel: label)
  }
}
