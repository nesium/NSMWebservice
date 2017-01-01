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
    
    private let dict: [String: Any]
    private let className: String
    
    internal init(_ dict: [String: Any], className: String) {
        self.dict = dict
        self.className = className
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
    
    public func decode(_ key: String) throws -> NSDecimalNumber {
        return try decode(key, transformer: decimalNumberTransformer)
    }
    
    public func decode(_ key: String) throws -> NSDecimalNumber? {
        return try decode(key, transformer: decimalNumberTransformer)
    }
}



public class JSONEncoder {
    
    private(set) var jsonDictionary: [String: Any] = [:]
    private let className: String
    
    internal init(className: String) {
        self.className = className
    }
    
    public func encode<T: JSONValue>(_ key: String, _ value: T) {
        jsonDictionary[key] = value
    }
    
    public func encode<T: JSONValue>(_ key: String, _ value: T?) {
        if value != nil {
            encode(key, value!)
        }
    }
    
    public func encode<Transformer: ValueTransformer>(_ key: String,
    	_ value: Transformer.OutType, transformer: Transformer) {
        encode(key, transformer.reverseTransformedValue(value))
    }
    
    public func encode<Transformer: ValueTransformer>(_ key: String,
    	_ value: Transformer.OutType?, transformer: Transformer) {
        if value != nil {
            encode(key, value!, transformer: transformer)
        }
    }
    
    public func encode(_ key: String, _ value: Date) {
        encode(key, value, transformer: dateTransformer)
    }
    
    public func encode(_ key: String, _ value: Date?) {
        encode(key, value, transformer: dateTransformer)
    }
    
    public func encode(_ key: String, _ value: URL) {
        encode(key, value, transformer: urlTransformer)
    }
    
    public func encode(_ key: String, _ value: URL?) {
        encode(key, value, transformer: urlTransformer)
    }
    
    public func encode(_ key: String, _ value: NSDecimalNumber) {
        encode(key, value, transformer: decimalNumberTransformer)
    }
    
    public func encode(_ key: String, _ value: NSDecimalNumber?) {
        encode(key, value, transformer: decimalNumberTransformer)
    }
}
