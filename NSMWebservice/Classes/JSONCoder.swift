//
//  JSONCoder.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 01/01/2017.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation


public protocol JSONValue: JSONCompatible {}

extension String: JSONValue {}
extension Int: JSONValue {}
extension Int8: JSONValue {}
extension Int16: JSONValue {}
extension Int32: JSONValue {}
extension Int64: JSONValue {}
extension Double: JSONValue {}
extension Float: JSONValue {}
extension Bool: JSONValue {}

extension NSDictionary: JSONValue {}
extension NSString: JSONValue {}
extension NSNumber: JSONValue {}

private let dateTransformer: ISO8601DateTimeTransformer = {
  return ISO8601DateTimeTransformer()
}()

private let urlTransformer: URLTransformer = {
  return URLTransformer()
}()

private let dictionaryTransformer: JSONDictionaryTransformer = {
  return JSONDictionaryTransformer()
}()

public class JSONDecoder {

  public let deserializationContext: Any?

  private let deserializer: JSONDeserializer

  private let dict: [String: Any]
  private let className: String

  // MARK: - Initialization -

  internal init(_ dict: [String: Any], className: String, deserializer: JSONDeserializer,
    deserializationContext: Any?) {
    self.dict = dict
    self.className = className
    self.deserializer = deserializer
    self.deserializationContext = deserializationContext
  }

  // MARK: - Decoding a JSONValue -
  
  public func decode<T: JSONValue>(_ key: String) throws -> T {
    guard let value = dict[key] else {
      throw ParseError.missingField(key, cls: className)
    }

    guard let result = value as? T else {
      throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
        found: String(describing: type(of: value)), cls: className)
    }

    return result
  }

  public func decode<T: JSONValue>(_ key: String) throws -> T? {
    guard let value = dict[key] else {
      return nil
    }

    guard let result = value as? T else {
      throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
        found: String(describing: type(of: value)), cls: className)
    }

    return result
  }

  // MARK: - Decoding an array of JSONValues -

  public func decode<T: JSONValue>(_ key: String) throws -> [T] {
    guard let value = dict[key] else {
      throw ParseError.missingField(key, cls: className)
    }

    guard let result = value as? [T] else {
      throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
        found: String(describing: type(of: value)), cls: className)
    }

    return result
  }

  public func decode<T: JSONValue>(_ key: String) throws -> [T]? {
    guard let value = dict[key] else {
      return nil
    }

    guard let result = value as? [T] else {
      throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
        found: String(describing: type(of: value)), cls: className)
    }

    return result
  }

  // MARK: - Decoding a JSONConvertible -

  public func decode<T: JSONConvertible>(_ key: String) throws -> T {
    guard let value = dict[key] else {
      throw ParseError.missingField(key, cls: className)
    }

    guard let dict = value as? [String: Any] else {
      throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
        found: String(describing: type(of: value)), cls: className)
    }

    return try deserializer.deserialize(dict)
  }

  public func decode<T: JSONConvertible>(_ key: String) throws -> T? {
    guard let value = dict[key] else {
      return nil
    }

    guard let dict = value as? [String: Any] else {
      throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
        found: String(describing: type(of: value)), cls: className)
    }

    return try deserializer.deserialize(dict) as T
  }

  // MARK: - Decoding an array of JSONConvertibles -

  public func decode<T: JSONConvertible>(_ key: String) throws -> [T] {
    guard let value = dict[key] else {
      throw ParseError.missingField(key, cls: className)
    }

    guard let result = value as? [[String: Any]] else {
      throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
        found: String(describing: type(of: value)), cls: className)
    }

    return try result.map { item in
      try deserializer.deserialize(item)
    }
  }
  
  public func decode<T: JSONConvertible>(_ key: String) throws -> [T]? {
    guard let value = dict[key] else {
      return nil
    }

    guard let result = value as? [[String: Any]] else {
      throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
        found: String(describing: type(of: value)), cls: className)
    }

    return try result.map { item in
      return try deserializer.deserialize(item)
    }
  }

  // MARK: - Decoding a value using a ValueTransformer -

  public func decode<Transformer: ValueTransformer>(_ key: String,
    transformer: Transformer) throws -> Transformer.OutType {
    let value: Transformer.InType = try decode(key)
    return try transformer.transformedValue(value)
  }

  public func decode<Transformer: ValueTransformer>(_ key: String,
    transformer: Transformer) throws -> Transformer.OutType? {
    guard let value: Transformer.InType = try decode(key) else {
      return nil
    }
    return try transformer.transformedValue(value)
  }

  // MARK: - Convenience methods for decoding common types which would require a ValueTransformer  -

  public func decode(_ key: String) throws -> Date {
    return try decode(key, transformer: dateTransformer)
  }

  public func decode(_ key: String) throws -> Date? {
    return try decode(key, transformer: dateTransformer)
  }

  public func decode(_ key: String) throws -> URL {
    return try decode(key, transformer: urlTransformer)
  }

  public func decode(_ key: String) throws -> URL? {
    return try decode(key, transformer: urlTransformer)
  }

  public func decode(_ key: String) throws -> JSONDictionary {
    return try decode(key, transformer: dictionaryTransformer)
  }

  public func decode(_ key: String) throws -> JSONDictionary? {
    return try decode(key, transformer: dictionaryTransformer)
  }
}




public class JSONEncoder {

  private(set) var jsonDictionary: [String: Any] = [:]
  private let className: String

  // MARK: - Initialization -

  internal init(className: String) {
    self.className = className
  }

  // MARK: - Encoding JSONValue(s) -

  public func encode<T: JSONValue>(_ key: String, _ value: T?) throws {
    if let value = value {
      jsonDictionary[key] = value
    }
  }

  public func encode<T: JSONValue>(_ key: String, _ value: [T]?) throws {
    if let value = value {
      jsonDictionary[key] = value
    }
  }

  // MARK: - Encoding JSONConvertible(s)  -

  public func encode<T: JSONConvertible>(_ key: String, _ value: T?) throws {
    if let value = value {
      jsonDictionary[key] = try value.JSONObject()
    }
  }

  public func encode<T: JSONConvertible>(_ key: String, _ value: [T]?) throws {
    if let value = value {
      jsonDictionary[key] = try value.map { item in
        try item.JSONObject()
      }
    }
  }

  // MARK: - Encoding a value using a ValueTransformer -

  public func encode<Transformer: ValueTransformer>(_ key: String,
    _ value: Transformer.OutType?, transformer: Transformer) throws {
    if let value = value {
      try encode(key, transformer.reverseTransformedValue(value))
    }
  }

  // MARK: - Convenience methods for encoding common types which would require a ValueTransformer  -

  public func encode(_ key: String, _ value: Date?) throws {
    try encode(key, value, transformer: dateTransformer)
  }

  public func encode(_ key: String, _ value: URL?) throws {
    try encode(key, value, transformer: urlTransformer)
  }

  public func encode(_ key: String, _ value: JSONDictionary?) throws {
    try encode(key, value, transformer: dictionaryTransformer)
  }
}
