//
//  JSONConvertible.swift
//  Bookshelf
//
//  Created by Marc Bauer on 15.09.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation

public protocol JSONConvertible {
    init(decoder: JSONDecoder) throws
    func encode(encoder: JSONEncoder) throws
    
    static var JSONClassName: String { get }
}

extension JSONConvertible {
    func JSONObjectIncludingClassName() throws -> [String: Any] {
        let encoder = JSONEncoder(className: String(describing: type(of: self)))
        try self.encode(encoder: encoder)
        var obj = encoder.jsonDictionary
        obj[classNameKey] = type(of: self).JSONClassName
        return obj
    }
}
