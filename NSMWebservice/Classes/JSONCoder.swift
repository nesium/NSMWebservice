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
extension Double: JSONValue {}
extension Float: JSONValue {}
extension Bool: JSONValue {}

private let dateTransformer: DateTimeTransformer = {
    return DateTimeTransformer()
}()

public class JSONDecoder {
    
    private let dict: [String: Any]
    private let className: String
    
    internal init(_ dict: [String: Any], className: String) {
        self.dict = dict
        self.className = className
    }
    
    func decode<T: JSONValue>(_ key: String) throws -> T {
        guard let value = dict[key] else {
            throw ParseError.missingField(key, cls: className)
        }
        
        guard let result = value as? T else {
            throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
            	found: String(describing: type(of: value)), cls: className)
        }
        
        return result
    }
    
    func decode<T: JSONValue>(_ key: String) throws -> T? {
        guard let value = dict[key] else {
            return nil
        }
        
        guard let result = value as? T else {
            throw ParseError.incorrectFieldType(key, expected: String(describing: T.self),
            	found: String(describing: type(of: value)), cls: className)
        }
        
        return result
    }
    
    func decode(_ key: String) throws -> Date {
        let dateString: String = try decode(key)
        return try dateTransformer.transformedValue(dateString)
    }
    
    func decode(_ key: String) throws -> Date? {
        let dateString: String? = try decode(key)
        
        guard dateString != nil else {
            return nil
        }
        return try dateTransformer.transformedValue(dateString!)
    }
}



public class JSONEncoder {
    
    private(set) var jsonDictionary: [String: Any] = [:]
    private let className: String
    
    internal init(className: String) {
        self.className = className
    }
    
    func encode<T: JSONValue>(_ key: String, _ value: T) {
        jsonDictionary[key] = value
    }
    
    func encode<T: JSONValue>(_ key: String, _ value: T?) {
        if value != nil {
            encode(key, value!)
        }
    }
    
    func encode(_ key: String, _ value: Date) {
        jsonDictionary[key] = dateTransformer.reverseTransformedValue(value)
    }
    
    func encode(_ key: String, _ value: Date?) {
        if value != nil {
            encode(key, value!)
        }
    }
}
