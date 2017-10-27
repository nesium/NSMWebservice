//
//  JSONConvertible.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 15.09.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation

public protocol JSONCompatible {}


public struct JSONDictionary: Collection {
  private var store: [String: JSONValue]

  public typealias DictionaryType = Dictionary<String, JSONValue>
  public typealias IndexDistance = DictionaryType.IndexDistance
  public typealias Indices = DictionaryType.Indices
  public typealias Iterator = DictionaryType.Iterator
  public typealias SubSequence = DictionaryType.SubSequence

  public var startIndex: Index { return self.store.startIndex }
  public var endIndex: DictionaryType.Index { return self.store.endIndex }
  public subscript(position: Index) -> Iterator.Element { return self.store[position] }
  public subscript(bounds: Range<Index>) -> SubSequence { return self.store[bounds] }
  public var indices: Indices { return self.store.indices }

  public var dictionary: [String: JSONValue] {
    return self.store
  }

  public init(dictionary: [String: JSONValue]) {
    self.store = dictionary
  }

  public subscript(key: String) -> JSONValue? {
    get { return self.store[key] }
    set { self.store[key] = newValue }
  }

  public func index(after i: Index) -> Index {
    return self.store.index(after: i)
  }

  public func makeIterator() -> DictionaryIterator<String, JSONValue> {
    return self.store.makeIterator()
  }

  public typealias Index = DictionaryType.Index
}


extension JSONDictionary: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, JSONValue)...) {
    self.init(dictionary: Dictionary.init(elements, uniquingKeysWith: { (key, _) in key }))
  }
}


public protocol JSONConvertible: JSONCompatible {
  init(decoder: JSONDecoder) throws
  func encode(encoder: JSONEncoder) throws
}

public extension JSONConvertible {
  public func JSONObject() throws -> [String: Any] {
    let encoder = JSONEncoder(className: String(describing: type(of: self)))
    try self.encode(encoder: encoder)
    return encoder.jsonDictionary
  }

  public func JSONData(options: JSONSerialization.WritingOptions = []) throws -> Data {
    return try JSONSerialization.data(withJSONObject: self.JSONObject(), options: options)
  }

  public static func fromJSONObject(_ dict: [String: Any]) throws -> Self {
    let deserializer = JSONDeserializer(deserializationContext: nil)
    return try deserializer.deserialize(dict)
  }

  public static func fromJSONData(_ data: Data) throws -> Self {
    let deserializer = JSONDeserializer(deserializationContext: nil)
    return try deserializer.deserialize(data)
  }

  public static func fromJSONObject(_ arr: [[String: Any]]) throws -> [Self] {
    let deserializer = JSONDeserializer(deserializationContext: nil)
    return try arr.map { try deserializer.deserialize($0) }
  }
}
