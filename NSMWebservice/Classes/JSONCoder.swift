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

extension NSString: JSONValue {}
extension NSNumber: JSONValue {}

public typealias JSONDictionary = [String: JSONValue]

private let dateTransformer: ISO8601DateTimeTransformer = {
  return ISO8601DateTimeTransformer()
}()

private let urlTransformer: URLTransformer = {
  return URLTransformer()
}()
