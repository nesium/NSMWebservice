//
//  Keychain.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 02.01.16.
//  Copyright © 2016 nesiumdotcom. All rights reserved.
//

import Foundation

public enum KeychainError: Error {
  case missingHostInServiceURL
  case unhandledError(status: OSStatus)
  case unexpectedPasswordData
}

public struct Keychain {
  public enum Accessibility {
    case whenUnlocked
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlock
    case afterFirstUnlockThisDeviceOnly
    case always
    case alwaysThisDeviceOnly
    case whenPasscodeSetThisDeviceOnly

    fileprivate var keychainValue: CFString {
      switch self {
        case .whenUnlocked:
          return kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly:
          return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlock:
          return kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly:
          return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .always:
          return kSecAttrAccessibleAlways
        case .alwaysThisDeviceOnly:
          return kSecAttrAccessibleAlwaysThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly:
          return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
      }
    }
  }

  public struct Item {
    public let account: String
    public let password: String?
    public let token: String?
    public let refreshToken: String?

    public init(
      account: String,
      password: String?,
      token: String?,
      refreshToken: String?
    ) {
      self.account = account
      self.password = password
      self.token = token
      self.refreshToken = refreshToken
    }
  }

  // MARK: - Public Methods -

  public static func fetchItem(
    for serviceURL: URL,
    accessGroup: String? = nil
  ) throws -> Keychain.Item? {
    var query = try self.query(for: serviceURL, accessGroup: accessGroup)
    query[(kSecMatchLimit as String)] = kSecMatchLimitOne
    query[(kSecReturnAttributes as String)] = true
    query[(kSecReturnData as String)] = true

    var queryResult: AnyObject?
    let status = withUnsafeMutablePointer(to: &queryResult) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }

    guard status != errSecItemNotFound else {
      return nil
    }

    guard status == noErr else {
      throw KeychainError.unhandledError(status: status)
    }

    guard let existingItem = queryResult as? [String : Any],
      let data = existingItem[kSecValueData as String] as? Data else {
      throw KeychainError.unexpectedPasswordData
    }

    do {
      return try JSONDecoder().decode(Keychain.Item.self, from: data)
    } catch {
      throw KeychainError.unexpectedPasswordData
    }
  }

  public static func put(
    item: Keychain.Item,
    for serviceURL: URL,
    accessibility: Accessibility = .whenUnlocked,
    accessGroup: String? = nil
  ) throws {
    var fetchQuery = try self.query(for: serviceURL, accessGroup: accessGroup)
    fetchQuery[(kSecMatchLimit as String)] = kSecMatchLimitOne

    let itemData = try JSONEncoder().encode(item)

    if SecItemCopyMatching(fetchQuery as CFDictionary, nil) == errSecSuccess {
      let query = try self.query(for: serviceURL, accessGroup: accessGroup)
      let attributesToUpdate: [String: Any] = [
        (kSecValueData as String): itemData,
        (kSecAttrAccessible as String): accessibility.keychainValue
      ]
      let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

      guard status == noErr else {
        throw KeychainError.unhandledError(status: status)
      }
    } else {
      var query = try self.query(for: serviceURL, accessGroup: accessGroup)
      query[(kSecValueData as String)] = itemData
      query[(kSecAttrAccessible as String)] = accessibility.keychainValue
      let status = SecItemAdd(query as CFDictionary, nil)

      guard status == noErr else {
        throw KeychainError.unhandledError(status: status)
      }
    }
  }

  public static func deleteItem(for serviceURL: URL, accessGroup: String? = nil) throws {
    let query = try self.query(for: serviceURL, accessGroup: accessGroup)
    let status = SecItemDelete(query as CFDictionary)

    guard status == noErr || status == errSecItemNotFound else {
      throw KeychainError.unhandledError(status: status)
    }
  }

  // MARK: - Private Methods -

  private static func query(for serviceURL: URL, accessGroup: String?) throws -> [String: Any] {
    guard let host = serviceURL.host else {
      throw KeychainError.missingHostInServiceURL
    }

    var query: [String: Any] = [
      (kSecClass as String): kSecClassInternetPassword,
      (kSecAttrServer as String): host,
      (kSecAttrPath as String): serviceURL.path
    ]

    if let accessGroup = accessGroup {
      query[(kSecAttrAccessGroup as String)] = accessGroup
    }

    return query
  }
}

extension Keychain.Item: Codable {
  enum CodingKeys: String, CodingKey {
    case account = "acc"
    case password = "pw"
    case token = "tok"
    case refreshToken = "rtok"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.account = try container.decode(String.self, forKey: .account)
    self.password = try container.decodeIfPresent(String.self, forKey: .password)
    self.token = try container.decodeIfPresent(String.self, forKey: .token)
    self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.account, forKey: .account)
    try container.encode(self.password, forKey: .password)
    try container.encode(self.token, forKey: .token)
    try container.encode(self.refreshToken, forKey: .refreshToken)
  }
}

extension Keychain.Item: Equatable {
  public static func ==(lhs: Keychain.Item, rhs: Keychain.Item) -> Bool {
    return lhs.account == rhs.account &&
      lhs.password == rhs.password &&
      lhs.token == rhs.token &&
      lhs.refreshToken == rhs.refreshToken
  }
}
