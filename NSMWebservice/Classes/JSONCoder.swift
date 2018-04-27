//
//  JSONCoder.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 01/01/2017.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation


public protocol JSONValue {}

extension Bool: JSONValue {}
extension Int: JSONValue {}
extension Int8: JSONValue {}
extension Int16: JSONValue {}
extension Int32: JSONValue {}
extension Int64: JSONValue {}
extension UInt: JSONValue {}
extension UInt8: JSONValue {}
extension UInt16: JSONValue {}
extension UInt32: JSONValue {}
extension UInt64: JSONValue {}
extension Double: JSONValue {}
extension Float: JSONValue {}
extension String: JSONValue {}
extension Date: JSONValue {}



extension KeyedEncodingContainer {
  public mutating func ws_encodeIfPresent<T: JSONValue>(_ value: T?, forKey key: K) throws {
    guard let value = value else {
      return
    }
    try self.ws_encode(value, forKey: key)
  }

  public mutating func ws_encode<T: JSONValue>(_ value: T, forKey key: K) throws {
    switch value.self {
      case let value as Bool:
        try self.encode(value, forKey: key)
      case let value as Int:
        try self.encode(value, forKey: key)
      case let value as Int8:
        try self.encode(value, forKey: key)
      case let value as Int16:
        try self.encode(value, forKey: key)
      case let value as Int32:
        try self.encode(value, forKey: key)
      case let value as Int64:
        try self.encode(value, forKey: key)
      case let value as UInt:
        try self.encode(value, forKey: key)
      case let value as UInt8:
        try self.encode(value, forKey: key)
      case let value as UInt16:
        try self.encode(value, forKey: key)
      case let value as UInt32:
        try self.encode(value, forKey: key)
      case let value as UInt64:
        try self.encode(value, forKey: key)
      case let value as Double:
        try self.encode(value, forKey: key)
      case let value as Float:
        try self.encode(value, forKey: key)
      case let value as String:
        try self.encode(value, forKey: key)
      case is Date:
        fatalError("Date is not supported yet")
      default:
        fatalError("Unknown type \(String(describing: T.self))")
    }
  }
}


extension KeyedDecodingContainer {
  public func ws_decodeIfPresent<T: JSONValue>(_ type: T.Type, forKey key: K) throws -> T? {
    switch type {
      case is Bool.Type:
        return try self.decodeIfPresent(Bool.self, forKey: key) as? T
      case is Int.Type:
        return try self.decodeIfPresent(Int.self, forKey: key) as? T
      case is Int8.Type:
        return try self.decodeIfPresent(Int8.self, forKey: key) as? T
      case is Int16.Type:
        return try self.decodeIfPresent(Int16.self, forKey: key) as? T
      case is Int32.Type:
        return try self.decodeIfPresent(Int32.self, forKey: key) as? T
      case is Int64.Type:
        return try self.decodeIfPresent(Int64.self, forKey: key) as? T
      case is UInt.Type:
        return try self.decodeIfPresent(UInt.self, forKey: key) as? T
      case is UInt8.Type:
        return try self.decodeIfPresent(UInt8.self, forKey: key) as? T
      case is UInt16.Type:
        return try self.decodeIfPresent(UInt16.self, forKey: key) as? T
      case is UInt32.Type:
        return try self.decodeIfPresent(UInt32.self, forKey: key) as? T
      case is UInt64.Type:
        return try self.decodeIfPresent(UInt64.self, forKey: key) as? T
      case is Double.Type:
        return try self.decodeIfPresent(Double.self, forKey: key) as? T
      case is Float.Type:
        return try self.decodeIfPresent(Float.self, forKey: key) as? T
      case is String.Type:
        return try self.decodeIfPresent(String.self, forKey: key) as? T
      case is Date.Type:
        fatalError("Date is not supported yet")
      default:
        fatalError("Unknown type \(String(describing: type))")
    }
  }

  public func ws_decode<T: JSONValue>(_ type: T.Type, forKey key: K) throws -> T {
    switch type {
      case is Bool.Type:
        return try self.decode(Bool.self, forKey: key) as! T
      case is Int.Type:
        return try self.decode(Int.self, forKey: key) as! T
      case is Int8.Type:
        return try self.decode(Int8.self, forKey: key) as! T
      case is Int16.Type:
        return try self.decode(Int16.self, forKey: key) as! T
      case is Int32.Type:
        return try self.decode(Int32.self, forKey: key) as! T
      case is Int64.Type:
        return try self.decode(Int64.self, forKey: key) as! T
      case is UInt.Type:
        return try self.decode(UInt.self, forKey: key) as! T
      case is UInt8.Type:
        return try self.decode(UInt8.self, forKey: key) as! T
      case is UInt16.Type:
        return try self.decode(UInt16.self, forKey: key) as! T
      case is UInt32.Type:
        return try self.decode(UInt32.self, forKey: key) as! T
      case is UInt64.Type:
        return try self.decode(UInt64.self, forKey: key) as! T
      case is Double.Type:
        return try self.decode(Double.self, forKey: key) as! T
      case is Float.Type:
        return try self.decode(Float.self, forKey: key) as! T
      case is String.Type:
        return try self.decode(String.self, forKey: key) as! T
      case is Date.Type:
        fatalError("Date is not supported yet")
      default:
        fatalError("Unknown type \(String(describing: type))")
    }
  }
}
