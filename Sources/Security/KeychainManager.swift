//
//  KeychainManager.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/26/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation
import Security

public class KeychainManager {
  public static let shared = KeychainManager()

  private typealias KeychainClass = CFString
  private typealias KeychainValue = AnyObject
  private typealias KeychainQuery = [NSString: AnyObject]
  private let accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

  public func add(certificate: SecCertificate, label: String) throws {
    try add(value: certificate, label: label)
  }

  public func find(certificateWithLabel label: String) throws -> SecCertificate {
    return try find(kSecClassCertificate, label: label)
  }

  public func remove(certificateWithLabel label: String) throws {
    try remove(kSecClassCertificate, label: label)
  }

  public func add(identity: SecIdentity, label: String) throws {
    try add(value: identity, label: label)
  }

  public func find(identityWithLabel label: String) throws -> SecIdentity {
    return try find(kSecClassIdentity, label: label)
  }

  public func remove(identityWithLabel label: String) throws {
    try remove(kSecClassIdentity, label: label)
  }

  private func add(value: KeychainValue, label: String) throws {
    // Don't specify kSecClass otherwise SecItemCopyMatching won't be able to find identities
    let query: KeychainQuery = [
      kSecAttrLabel: label as NSString,
      kSecAttrAccessible: accessibility,
      kSecValueRef: value
    ]

    var result: AnyObject?
    let status = SecItemAdd(query as CFDictionary, &result)
    guard status == errSecSuccess else { throw KeychainError(code: status) }
  }

  private func find<T>(_ kClass: KeychainClass, label: String) throws -> T {
    let query: KeychainQuery = [
      kSecClass: kClass,
      kSecAttrLabel: label as NSString,
      kSecReturnRef: kCFBooleanTrue
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(code: status) }
    guard let item = result else { throw KeychainError.itemNotFound }
    guard let typedItem = item as? T else { throw KeychainError.invalidResult }

    return typedItem
  }

  private func remove(_ kClass: KeychainClass, label: String) throws {
    let query: KeychainQuery = [
      kSecClass: kClass,
      kSecAttrLabel: label as NSString
    ]

    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess else { throw KeychainError(code: status) }
  }
}

public enum KeychainError: Error {
  case invalidResult
  case itemAlreadyExists
  case itemNotFound
  case other(code: OSStatus)

  init(code: OSStatus) {
    switch code {
    case errSecDuplicateItem:
      self = .itemAlreadyExists
    case errSecItemNotFound:
      self = .itemNotFound
    default:
      self = .other(code: code)
    }
  }
}

extension KeychainError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .invalidResult:
      return "The keychain item returned wasn't of the expected type"
    case .itemAlreadyExists:
      return "The keychain item already exists"
    case .itemNotFound:
      return "The keychain item doesn't exist"
    case .other(let code):
      return "The keychain operation failed with code \(code)"
    }
  }
}
