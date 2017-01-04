//
//  JSONCoder.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 01/01/2017.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation


public protocol JSONValue {}

extension String: JSONValue {}
extension Int: JSONValue {}
extension Int8: JSONValue {}
extension Int16: JSONValue {}
extension Int32: JSONValue {}
extension Int64: JSONValue {}
extension Double: JSONValue {}
extension Float: JSONValue {}
extension Bool: JSONValue {}

private let dateTransformer: DateTimeTransformer = {
    return DateTimeTransformer()
}()

private let urlTransformer: URLTransformer = {
    return URLTransformer()
}()

private let decimalNumberTransformer: DecimalNumberTransformer = {
    return DecimalNumberTransformer()
}()

public class JSONDecoder {
    
    public let deserializationContext: Any?
    
    private let deserializer: JSONDeserializer
    
    private let dict: [String: Any]
    private let className: String
    
    internal init(_ dict: [String: Any], className: String, deserializer: JSONDeserializer,
        deserializationContext: Any?) {
        self.dict = dict
        self.className = className
        self.deserializer = deserializer
        self.deserializationContext = deserializationContext
    }
    
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
        
        return try deserializer.deserialize(dict)
    }
    
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
    
    public func decode<T: JSONConvertible>(_ key: String) throws -> [T] {
        guard let value = dict[key] else {
            throw ParseError.missingField(key, cls: className)
        }
        
        guard let result = value as? [[String: Any]] else {
            throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
            	found: String(describing: type(of: value)), cls: className)
        }
        
        return try result.map { item in
            return try deserializer.deserialize(item)
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
    
    public func decode<Transformer: ValueTransformer>(_ key: String,
        transformer: Transformer) throws -> Transformer.OutType {
        let value: Transformer.InType = try decode(key)
        return try transformer.transformedValue(value)
    }
    
    public func decode<Transformer: ValueTransformer>(_ key: String,
        transformer: Transformer) throws -> Transformer.OutType? {
        let value: Transformer.InType? = try decode(key)
        
        guard value != nil else {
            return nil
        }
        
        return try transformer.transformedValue(value!)
    }
    
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
}



public class JSONEncoder {
    
    private(set) var jsonDictionary: [String: Any] = [:]
    private let className: String
    
    internal init(className: String) {
        self.className = className
    }
    
    public func encode<T: JSONValue>(_ key: String, _ value: T?) throws {
        guard value != nil else {
            return
        }
        
        jsonDictionary[key] = value!
    }
    
    public func encode<T: JSONConvertible>(_ key: String, _ value: T?) throws {
        guard value != nil else {
            return
        }
        
        jsonDictionary[key] = try value?.JSONObjectIncludingClassName()
    }
    
    public func encode<T: JSONValue>(_ key: String, _ value: [T]?) throws {
        guard value != nil else {
            return
        }
        
        jsonDictionary[key] = value!
    }
    
    public func encode<T: JSONConvertible>(_ key: String, _ value: [T]?) throws {
        guard value != nil else {
            return
        }
        
        jsonDictionary[key] = try value!.map { item in
            return try item.JSONObjectIncludingClassName()
        }
    }
    
    public func encode<Transformer: ValueTransformer>(_ key: String,
    	_ value: Transformer.OutType?, transformer: Transformer) throws {
        guard value != nil else {
            return
        }
        
        try encode(key, transformer.reverseTransformedValue(value!))
    }
    
    public func encode(_ key: String, _ value: Date?) throws {
        try encode(key, value, transformer: dateTransformer)
    }
    
    public func encode(_ key: String, _ value: URL?) throws {
        try encode(key, value, transformer: urlTransformer)
    }
}
