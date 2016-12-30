//
//  NSFormatterExtensions.swift
//  Bookshelf
//
//  Created by Marc Bauer on 18.09.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation

extension Formatter {
    func objectValueForString<T>(_ str: String) throws -> T {
        var obj: AnyObject?
        var errMsg: NSString?
        
        guard self.getObjectValue(&obj, for: str, errorDescription: &errMsg) else {
            throw ParseError.formattingFailed(msg:
                (errMsg as String? ?? "Could not parse '\(str)' as \(T.self)") as String)
        }
        
        guard obj is T else {
            throw ParseError.formattingFailed(msg: "Parsing \(str) did not produce a \(T.self)")
        }
        
        return obj as! T
    }
}
