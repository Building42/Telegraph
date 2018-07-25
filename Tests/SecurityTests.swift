//
//  SecurityTests.swift
//  TelegraphTests
//
//  Created by Yvo van Beek on 1/26/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import XCTest
import Telegraph

class SecurityTests: XCTestCase {
  private let testCertificateLabel = "Cert-Test"
  private var testCertificateURL: URL!

  private let testIdentityLabel = "Identity-Test"
  private var testIdentityURL: URL!

  override func setUp() {
    super.setUp()

    let testBundle = Bundle(for: SecurityTests.self)
    testCertificateURL = testBundle.url(forResource: "localhost", withExtension: "der")!
    testIdentityURL = testBundle.url(forResource: "localhost", withExtension: "p12")!
  }

  func testCertificateCreateFromDER() {
    let testCertificate = Certificate(derURL: testCertificateURL)
    XCTAssertNotNil(testCertificate, "Certificate could not be created from DER file")
  }

  func testCertificateKeychainMethods() {
    let testCertificate = Certificate(derURL: testCertificateURL)!

    // Remove certificate in case a previous test failed
    try? Certificate.removeFromKeychain(label: testCertificateLabel)

    // Test adding the certificate to the Keychain
    do {
      try testCertificate.addToKeychain(label: testCertificateLabel)
    } catch {
      XCTFail("Certificate could not be saved to keychain: \(error.localizedDescription)")
    }

    // Test loading the certificate from the Keychain
    do {
      let certificate = try Certificate(fromKeychain: testCertificateLabel)
      XCTAssertNotNil(certificate, "Certificate not found in keychain")
    } catch {
      XCTFail("Certificate could not be loaded from keychain: \(error.localizedDescription)")
    }

    // Test removing the certificate from the Keychain
    do {
      try Certificate.removeFromKeychain(label: testCertificateLabel)
    } catch {
      XCTFail("Certificate could not be removed from keychain: \(error.localizedDescription)")
    }
  }

  func testIdentityCreateFromPKCS12() {
    let testIdentity = CertificateIdentity(p12URL: testIdentityURL, passphrase: "test")
    XCTAssertNotNil(testIdentity, "Identity could not be created from PKCS12 file")
  }

  func testIdentityKeychainMethods() {
    let testIdentity = CertificateIdentity(p12URL: testIdentityURL, passphrase: "test")!

    // Remove identity in case a previous test failed
    try? CertificateIdentity.removeFromKeychain(label: testIdentityLabel)

    // Test adding the identity to the Keychain
    do {
      try testIdentity.addToKeychain(label: testIdentityLabel)
    } catch {
      XCTFail("Identity could not be saved to keychain: \(error.localizedDescription)")
    }

    // Test loading the identity from the Keychain
    do {
      let identity = try CertificateIdentity(fromKeychain: testIdentityLabel)
      XCTAssertNotNil(identity, "Identity not found in Keychain")
    } catch {
      XCTFail("Identity could not be loaded from keychain: \(error.localizedDescription)")
    }

    // Test removing the identity from the Keychain
    do {
      try CertificateIdentity.removeFromKeychain(label: testIdentityLabel)
    } catch {
      XCTFail("Identity could not be removed from keychain: \(error.localizedDescription)")
    }
  }
}
