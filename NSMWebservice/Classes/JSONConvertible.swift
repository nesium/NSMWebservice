//
//  JSONConvertible.swift
//  Bookshelf
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

extension JSONConvertible {
  func JSONObject() throws -> [String: Any] {
    let encoder = JSONEncoder(className: String(describing: type(of: self)))
    try self.encode(encoder: encoder)
    return encoder.jsonDictionary
  }
}
