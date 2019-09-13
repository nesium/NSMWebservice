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
    public var account: String
    public var password: String?
    public var token: String?
    public var refreshToken: String?

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

  public struct GenericItem {
    public var account: String
    public var username: String?
    public var email: String?
    public var password: String?

    public init(account: String, username: String?, email: String?, password: String?) {
      self.account = account
      self.username = username
      self.email = email
      self.password = password
    }
  }

  // MARK: - Public Methods -

  public static func fetchItem(
    for serviceURL: URL,
    account: String? = nil,
    accessGroup: String? = nil
  ) throws -> Keychain.Item? {
    var query = try self.internetPasswordQuery(
      for: serviceURL,
      account: account,
      accessGroup: accessGroup
    )
    query[(kSecMatchLimit as String)] = kSecMatchLimitOne
    query[(kSecReturnAttributes as String)] = true
    query[(kSecReturnData as String)] = true

    return try self.fetch(with: query)
  }

  public static func fetchItem(
    for service: String,
    account: String,
    accessGroup: String? = nil
  ) throws -> Keychain.GenericItem? {
    var query = try self.genericPasswordQuery(
      for: service,
      account: account,
      accessGroup: accessGroup
    )
    query[(kSecMatchLimit as String)] = kSecMatchLimitOne
    query[(kSecReturnAttributes as String)] = true
    query[(kSecReturnData as String)] = true

    return try self.fetch(with: query)
  }

  public static func put(
    item: Keychain.Item,
    for serviceURL: URL,
    account: String? = nil,
    accessibility: Accessibility = .whenUnlocked,
    accessGroup: String? = nil
  ) throws {
    try self.put(
      item: item,
      query: try self.internetPasswordQuery(
        for: serviceURL,
        account: account,
        accessGroup: accessGroup
      ),
      accessibility: accessibility
    )
  }

  public static func put(
    item: Keychain.GenericItem,
    for service: String,
    account: String? = nil,
    accessibility: Accessibility = .whenUnlocked,
    accessGroup: String? = nil
  ) throws {
    try self.put(
      item: item,
      query: try self.genericPasswordQuery(
        for: service,
        account: account,
        accessGroup: accessGroup
      ),
      accessibility: accessibility
    )
  }

  public static func deleteItem(
    for serviceURL: URL,
    account: String? = nil,
    accessGroup: String? = nil
  ) throws {
    try self.delete(
      with: try self.internetPasswordQuery(
        for: serviceURL,
        account: account,
        accessGroup: accessGroup
      )
    )
  }

  public static func deleteItem(
    for service: String,
    account: String? = nil,
    accessGroup: String? = nil
  ) throws {
    try self.delete(
      with: try self.genericPasswordQuery(for: service, account: account, accessGroup: accessGroup)
    )
  }

  // MARK: - Private Methods -

  private static func put<T: Encodable>(
    item: T,
    query: [String: Any],
    accessibility: Accessibility
  ) throws {
    var fetchQuery = query
    fetchQuery[(kSecMatchLimit as String)] = kSecMatchLimitOne

    let itemData = try JSONEncoder().encode(item)

    if SecItemCopyMatching(fetchQuery as CFDictionary, nil) == errSecSuccess {
      let attributesToUpdate: [String: Any] = [
        (kSecValueData as String): itemData,
        (kSecAttrAccessible as String): accessibility.keychainValue
      ]
      let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

      guard status == noErr else {
        throw KeychainError.unhandledError(status: status)
      }
    } else {
      var putQuery = query
      putQuery[(kSecValueData as String)] = itemData
      putQuery[(kSecAttrAccessible as String)] = accessibility.keychainValue
      let status = SecItemAdd(putQuery as CFDictionary, nil)

      guard status == noErr else {
        throw KeychainError.unhandledError(status: status)
      }
    }
  }

  private static func fetch<T: Decodable>(with query: [String: Any]) throws -> T? {
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
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw KeychainError.unexpectedPasswordData
    }
  }

  private static func delete(with query: [String: Any]) throws {
    let status = SecItemDelete(query as CFDictionary)

    guard status == noErr || status == errSecItemNotFound else {
      throw KeychainError.unhandledError(status: status)
    }
  }

  private static func internetPasswordQuery(
    for serviceURL: URL,
    account: String?,
    accessGroup: String?
  ) throws -> [String: Any] {
    guard let host = serviceURL.host else {
      throw KeychainError.missingHostInServiceURL
    }
    var query: [String: Any] = [
      (kSecClass as String): kSecClassInternetPassword,
      (kSecAttrServer as String): host,
      (kSecAttrPath as String): serviceURL.path
    ]
    if let account = account {
      query[(kSecAttrAccount as String)] = account
    }
    if let accessGroup = accessGroup {
      query[(kSecAttrAccessGroup as String)] = accessGroup
    }
    return query
  }

  private static func genericPasswordQuery(
    for service: String,
    account: String?,
    accessGroup: String?
  ) throws -> [String: Any] {
    var query: [String: Any] = [
      (kSecClass as String): kSecClassGenericPassword,
      (kSecAttrService as String): service
    ]
    if let account = account {
      query[kSecAttrAccount as String] = account
    }
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
}
extension Keychain.Item: Equatable {}


extension Keychain.GenericItem: Codable {
  enum CodingKeys: String, CodingKey {
    case account = "acc"
    case username = "un"
    case email = "em"
    case password = "pw"
  }
}
extension Keychain.GenericItem: Equatable {}
