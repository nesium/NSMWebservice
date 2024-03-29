//
//  ValueTransformer.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 18.09.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation

public protocol ValueTransformer {
  associatedtype InType: JSONValue
  associatedtype OutType

  func transformedValue(_ value: InType) throws -> OutType
  func reverseTransformedValue(_ value: OutType) -> InType
}

public enum ValueTransformerError: LocalizedError, CustomStringConvertible {
  case invalidValue(String)

  public var description: String {
    switch self {
      case .invalidValue(let message):
        return message
    }
  }

  public var errorDescription: String? {
    return self.description
  }
}

public struct ISO8601DateTimeTransformer : ValueTransformer {
  public typealias InType = String
  public typealias OutType = Date

  public init() {}

  public func transformedValue(_ value: InType) throws -> OutType {
    return try ISO8601DateTimeTransformer.formatter.objectValueForString(value)
  }

  public func reverseTransformedValue(_ value: OutType) -> InType {
    return ISO8601DateTimeTransformer.formatter.string(from: value)
  }

  internal static var formatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }
}

public struct URLTransformer : ValueTransformer {
  public typealias InType = String
  public typealias OutType = URL

  public init() {}

  public func transformedValue(_ value: InType) throws -> OutType {
    guard let url = URL(string: value) else {
      throw ValueTransformerError.invalidValue("'\(value)' is not a valid URL")
    }
    return url
  }

  public func reverseTransformedValue(_ value: OutType) -> InType {
    return value.absoluteString
  }
}
