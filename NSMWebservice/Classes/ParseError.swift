//
//  ParseError.swift
//  Bookshelf
//
//  Created by Marc Bauer on 30.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

public enum ParseError : Error {
    case invalidRootType
    case invalidLeafType
    case missingClassName
    case unexpectedResponse
    case unknownClassName(givenClassName: String)
    case missingField(String, cls: String)
    case incorrectFieldType(String, expected: String, found: String, cls: String)
    case formattingFailed(msg: String)
    
    var localizedDescription: String {
        switch self {
            case .invalidRootType:
                return "Invalid Root Type"
            case .invalidLeafType:
                return "Invalid Leaf Type"
            case .missingClassName:
                return "Missing Class Name"
            case .unexpectedResponse:
                return "Unexpected Response"
            case .unknownClassName(_):
                return "Invalid Class Name"
            case .missingField(let missingField, let className):
                return "Missing field '\(missingField)' in class \(className)"
            case .incorrectFieldType(let missingField, let expectedType, let foundType, let className):
                return "Found incorrect type for field '\(missingField)' in class \(className). Expected '\(expectedType)', found \(foundType) instead."
            case .formattingFailed(let errMsg):
                return errMsg
        }
    }
}
