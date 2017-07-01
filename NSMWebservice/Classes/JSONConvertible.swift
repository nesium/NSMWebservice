//
//  JSONConvertible.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 15.09.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation

public protocol JSONCompatible {}

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
