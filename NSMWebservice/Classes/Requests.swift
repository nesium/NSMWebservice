//
//  Requests.swift
//  Bookshelf
//
//  Created by Marc Bauer on 30.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation

public protocol Request {
    associatedtype U
    
    func success(_ handler: @escaping (U) -> Void) -> Self
    func failure(_ handler: @escaping (Error) -> Void) -> Self
}

public class ItemRequest<T>: Request, FulfillableRequest {
    public typealias U = T
    
    internal typealias JSONDeserializer = ([String: Any]) throws -> (U)
    
    internal lazy var successHandlers: [(U) -> ()] = Array<(U) -> ()>()
    internal lazy var failureHandlers: [(Error) -> ()] = Array<(Error) -> ()>()
    
    internal let deserializer: JSONDeserializer
    
    internal init(deserializer: @escaping JSONDeserializer) {
        self.deserializer = deserializer
    }
    
    @discardableResult public func success(_ handler: @escaping (U) -> Void) -> Self {
        successHandlers.append(handler)
        return self
    }
    
    @discardableResult public func failure(_ handler: @escaping (Error) -> Void) -> Self {
        failureHandlers.append(handler)
        return self
    }
}


public class CollectionRequest<T>: Request, FulfillableRequest {
    public typealias U = [T]
    
    internal typealias JSONDeserializer = ([String: Any]) throws -> (T)
    
    internal lazy var successHandlers: [(U) -> ()] = Array<(U) -> ()>()
    internal lazy var failureHandlers: [(Error) -> ()] = Array<(Error) -> ()>()
    
    internal let deserializer: JSONDeserializer
    
    internal init(deserializer: @escaping JSONDeserializer) {
        self.deserializer = deserializer
    }
    
    @discardableResult public func success(_ handler: @escaping (U) -> Void) -> Self {
        successHandlers.append(handler)
        return self
    }
    
    @discardableResult public func failure(_ handler: @escaping (Error) -> Void) -> Self {
        failureHandlers.append(handler)
        return self
    }
}
