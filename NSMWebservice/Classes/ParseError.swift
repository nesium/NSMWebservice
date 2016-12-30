//
//  ParseError.swift
//  Bookshelf
//
//  Created by Marc Bauer on 30.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

enum ParseError : Error {
    case invalidRootType
    case invalidLeafType
    case missingClassName
    case unexpectedResponse
    case unknownClassName(givenClassName: String)
    case missingFields(affectedClassName: String, missingFields: [String])
    case formattingFailed(msg: String)
}
