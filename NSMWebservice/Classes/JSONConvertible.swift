//
//  JSONConvertible.swift
//  Bookshelf
//
//  Created by Marc Bauer on 15.09.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation

public protocol JSONConvertible {
    init(json: [String: Any]) throws
    func JSONObject() -> [String: Any]
    static var JSONClassName: String { get }
}

extension JSONConvertible {
    func JSONObjectIncludingClassName() -> [String: Any] {
        var obj = self.JSONObject()
        obj[classNameKey] = type(of: self).JSONClassName
        return obj
    }
}
