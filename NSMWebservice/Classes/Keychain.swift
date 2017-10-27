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
  public struct Item {
    public let account: String
    public let password: String?
    public let token: String?
    public let refreshToken: String?
    public let userInfo: JSONDictionary?

    public init(
      account: String,
      password: String?,
      token: String?,
      refreshToken: String?,
      userInfo: JSONDictionary?) {
      self.account = account
      self.password = password
      self.token = token
      self.refreshToken = refreshToken
      self.userInfo = userInfo
    }
  }

  // MARK: - Public Methods -

  public static func fetchItem(
    for serviceURL: URL, accessGroup: String? = nil) throws -> Keychain.Item? {
    var query: [String: Any] = try self.query(for: serviceURL, accessGroup: accessGroup)
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
      return try Keychain.Item.fromJSONData(data)
    } catch {
      throw KeychainError.unexpectedPasswordData
    }
  }

  public static func put(item: Keychain.Item,
    for serviceURL: URL, accessGroup: String? = nil) throws {
    var fetchQuery: [String: Any] = try self.query(for: serviceURL, accessGroup: accessGroup)
    fetchQuery[(kSecMatchLimit as String)] = kSecMatchLimitOne

    let itemData: Data = try item.JSONData()

    if SecItemCopyMatching(fetchQuery as CFDictionary, nil) == errSecSuccess {
      let query: [String: Any] = try self.query(for: serviceURL, accessGroup: accessGroup)
      let attributesToUpdate: [String: Any] = [(kSecValueData as String): itemData]
      let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

      guard status == noErr else {
        throw KeychainError.unhandledError(status: status)
      }
    } else {
      var query: [String: Any] = try self.query(for: serviceURL, accessGroup: accessGroup)
      query[(kSecValueData as String)] = itemData
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



extension Keychain.Item: JSONConvertible {
  public init(decoder: JSONDecoder) throws {
    self.account = try decoder.decode("acc")
    self.password = try decoder.decode("pw")
    self.token = try decoder.decode("tok")
    self.refreshToken = try decoder.decode("rtok")
    self.userInfo = try decoder.decode("ui")
  }

  public func encode(encoder: JSONEncoder) throws {
    try encoder.encode("acc", self.account)
    try encoder.encode("pw", self.password)
    try encoder.encode("tok", self.token)
    try encoder.encode("rtok", self.refreshToken)
    try encoder.encode("ui", self.userInfo)
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
