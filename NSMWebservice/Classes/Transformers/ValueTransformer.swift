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



internal struct DateTimeTransformer : ValueTransformer {
  typealias InType = String
  typealias OutType = Date

  func transformedValue(_ value: InType) throws -> OutType {
    return try DateTimeTransformer.formatter.objectValueForString(value)
  }

  func reverseTransformedValue(_ value: OutType) -> InType {
    return DateTimeTransformer.formatter.string(from: value)
  }

  fileprivate static var formatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }
}



internal struct URLTransformer : ValueTransformer {
  typealias InType = String
  typealias OutType = URL

  func transformedValue(_ value: InType) throws -> OutType {
    guard let url = URL(string: value) else {
      throw ParseError.formattingFailed(msg: "'\(value)' is not a valid URL")
    }
    return url
  }

  func reverseTransformedValue(_ value: OutType) -> InType {
    return value.absoluteString
  }
}
