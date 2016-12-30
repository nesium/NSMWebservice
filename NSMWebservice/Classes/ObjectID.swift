//
//  ObjectID.swift
//  Bookshelf
//
//  Created by Marc Bauer on 30.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation

enum ObjectID : CustomStringConvertible {
    case permanent(id: Int)
    case transient(id: String)
    
    static func TransientID() -> ObjectID {
        return .transient(id: UUID().uuidString)
    }
    
    var description: String {
        switch self {
            case .permanent(let id):
                return String(id)
            case .transient(let id):
                return id
        }
    }
    
    var permanentID: Int? {
        get {
            switch self {
                case .permanent(let id):
                    return id
                case .transient(_):
                    return nil
            }
        }
    }
}
