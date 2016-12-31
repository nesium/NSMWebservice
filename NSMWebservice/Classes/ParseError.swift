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
    case missingFields([String], cls: String)
    case missingField(String, cls: String)
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
            case .missingFields(let missingFields, let className):
                let joinedFields = missingFields.joined(separator: ", ")
                return "Missing fields (\(joinedFields)) in class \(className)"
            case .missingField(let missingField, let className):
                return "Missing field '\(missingField)' in class \(className)"
            case .formattingFailed(let errMsg):
                return errMsg
        }
    }
}
