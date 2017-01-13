//
//  Session.swift
//  Bookshelf
//
//  Created by Marc Bauer on 29.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation
import PromiseKit
import Gzip

internal let classNameKey = "__cls__"

public struct WebserviceResponse<T> {
    public let data: T
    public let headerFields: [String: String]
    public let statusCode: HTTPStatus
}

public struct HTTPError: Error, CustomStringConvertible {
    public let headerFields: [String: String]
    public let statusCode: HTTPStatus
    
    public var description: String {
        return "The request failed. " +
            "The server responded with status code \(statusCode.description)."
    }
    
    public var localizedDescription: String {
        return self.description
    }
}

final public class Session: WebserviceSession {
    
    private let baseURL: URL
    private let session: URLSession
    
    public var headerFields: [String: String] = [:]
    public var gzipRequests: Bool = true
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.session = URLSession(
            configuration: URLSessionConfiguration.default)
    }

    public func request(item: JSONConvertible? = nil, path: String,
        method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<Void>> {
        let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
        let promise: ItemPromise<Void> = ItemPromise(deserializer: deserializer)
        performRequest(with: promise, item: item, path: path, method: method,
            timeoutInterval: timeoutInterval)
        return promise
    }
    
    public func request(items: [JSONConvertible], path: String,
        method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<Void>> {
        let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
        let promise: ItemPromise<Void> = ItemPromise(deserializer: deserializer)
        performRequest(with: promise, items: items, path: path, method: method,
            timeoutInterval: timeoutInterval)
        return promise
    }
    
    public func request<T: JSONCompatible>(_ cls: T.Type,
        item: JSONConvertible? = nil, path: String,
        method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<T>> {
        let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
        let promise: ItemPromise<T> = ItemPromise(deserializer: deserializer)
        performRequest(with: promise, item: item, path: path, method: method,
            timeoutInterval: timeoutInterval)
        return promise
    }
    
    public func requestCollection<T: JSONCompatible>(_ cls: T.Type,
        item: JSONConvertible? = nil, path: String,
        method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<[T]>> {
        let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
        let promise: CollectionPromise<T> = CollectionPromise(deserializer: deserializer)
        performRequest(with: promise, item: item, path: path, method: method,
            timeoutInterval: timeoutInterval)
        return promise
    }
    
    public func request<T: JSONCompatible>(_ cls: T.Type,
        items: [JSONConvertible], path: String,
        method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<T>> {
        let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
        let promise: ItemPromise<T> = ItemPromise(deserializer: deserializer)
        performRequest(with: promise, items: items, path: path, method: method,
            timeoutInterval: timeoutInterval)
        return promise
    }
    
    public func requestCollection<T: JSONCompatible>(_ cls: T.Type, items: [JSONConvertible],
        path: String, method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<[T]>> {
        let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
        let promise: CollectionPromise<T> = CollectionPromise(deserializer: deserializer)
        performRequest(with: promise, items: items, path: path, method: method,
            timeoutInterval: timeoutInterval)
        return promise
    }
    
    private func performRequest<ItemType, ResultType>(
        with promise: WebservicePromise<ItemType, ResultType>, item: JSONConvertible? = nil,
        path: String, method: HTTPMethod, timeoutInterval: TimeInterval) {
        var urlRequest = requestWithPath(path: path, method: method,
            timeoutInterval: timeoutInterval)
        
        if method.hasBody {
            if item != nil {
                do {
                    let data = try JSONSerialization.data(
                        withJSONObject: try item!.JSONObject(), options: [])
                    try append(data: data, to: &urlRequest)
                } catch {
                    promise.fail(error)
                    return
                }
            }
        }
        
        perform(request: urlRequest, promise: promise)
    }
    
    private func performRequest<ItemType, ResultType>(
        with promise: WebservicePromise<ItemType, ResultType>, items: [JSONConvertible],
        path: String, method: HTTPMethod, timeoutInterval: TimeInterval) {
        var urlRequest = requestWithPath(path: path, method: method,
            timeoutInterval: timeoutInterval)
        
        if method.hasBody {
            do {
                let jsonItems = try items.map { item in
                    return try item.JSONObject()
                }
                
                let data = try JSONSerialization.data(withJSONObject: jsonItems, options: [])
                try append(data: data, to: &urlRequest)
            } catch {
                promise.fail(error)
                return
            }
        }
        
        perform(request: urlRequest, promise: promise)
    }
    
    private func requestWithPath(path: String, method: HTTPMethod,
        timeoutInterval: TimeInterval) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var urlRequest = URLRequest(url: url)
        
        urlRequest.timeoutInterval = timeoutInterval
        
        headerFields.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        if method.hasBody {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpMethod = method.rawValue
        
        return urlRequest
    }
    
    private func perform<ItemType, ResultType>(request: URLRequest,
        promise: WebservicePromise<ItemType, ResultType>) {
        session.dataTask(with: request) { (data, response, error) -> Void in
            promise.fulfill(data: data, response: response, error: error)
        }.resume()
    }
    
    private func append(data: Data, to urlRequest: inout URLRequest) throws {
        if gzipRequests {
            urlRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            urlRequest.httpBody = try data.gzipped()
        } else {
            urlRequest.httpBody = data
        }
    }
}



fileprivate class WebservicePromise<ItemType, ResultType>: Promise<WebserviceResponse<ResultType>> {
    let deserializer: JSONDeserializer
    
    var fulfill: ((WebserviceResponse<ResultType>) -> Void)!
    var reject: ((Error) -> Void)!
    
    init(deserializer: JSONDeserializer) {
        self.deserializer = deserializer
        
        var fulfill: ((WebserviceResponse<ResultType>) -> Void)?
        var reject: ((Error) -> Void)?
        
        super.init() { f, r in
            fulfill = f
            reject = r
        }
        
        self.fulfill = fulfill!
        self.reject = reject!
    }
    
    required init(resolvers: (@escaping (WebserviceResponse<ResultType>) -> Void,
        @escaping (Error) -> Void) throws -> Void) {
        fatalError("init(resolvers:) has not been implemented")
    }
    
    required init(value: WebserviceResponse<ResultType>) {
        fatalError("init(value:) has not been implemented")
    }
    
    required init(error: Error) {
        fatalError("init(error:) has not been implemented")
    }
    
    func fulfill(data: Data?, response: URLResponse?, error: Error?) {
        guard error == nil else {
            fail(error!)
            return
        }
        
        guard data != nil else {
            let noDataError: Error = NSError(
            	domain: "",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey : "Server did not return data"]
            )
            fail(noDataError)
            return
        }
        
        
        var headers: [String: String]? = nil
        var statusCode: HTTPStatus = .Ok
        
        if let httpResponse = response as? HTTPURLResponse {
            headers = httpResponse.allHeaderFields as? [String: String]
            statusCode = HTTPStatus(rawValue: httpResponse.statusCode) ?? .UnknownError
        }
        
        guard statusCode.isSuccess else {
            fail(HTTPError(headerFields: headers ?? [:], statusCode: statusCode))
            return
        }
        
        if ResultType.self is Void.Type {
            fulfill(WebserviceResponse(
                data: () as! ResultType,
                headerFields: headers ?? [:],
                statusCode: statusCode))
            return
        }
        
        let obj: Any
        do {
            try obj = JSONSerialization.jsonObject(with: data!, options: [])
        } catch let parseError as NSError {
            fail(parseError)
            return
        }
        
        do {
            try fulfillWithJSONObject(obj, headers: headers, statusCode: statusCode)
        } catch let err {
            fail(err)
        }
    }
    
    func fail(_ error: Error) {
        reject(error)
    }
    
    func fulfillWithJSONObject(_ obj: Any, headers: [String: String]?,
        statusCode: HTTPStatus) throws {
        fatalError("fulfillWithJSONObject must be implemented in a subclass")
    }
}



fileprivate class ItemPromise<ItemType>: WebservicePromise<ItemType, ItemType> {
    
    override func fulfillWithJSONObject(_ obj: Any, headers: [String: String]?,
        statusCode: HTTPStatus) throws {
        guard let dict = obj as? [String: Any] else {
            throw ParseError.invalidLeafType
        }
        let result: ItemType = try deserializer.deserialize(dict)
        fulfill(WebserviceResponse(data: result, headerFields: headers ?? [:],
            statusCode: statusCode))
    }
}



fileprivate class CollectionPromise<ItemType>:
    WebservicePromise<ItemType, [ItemType]> {

    override func fulfillWithJSONObject(_ obj: Any, headers: [String: String]?,
        statusCode: HTTPStatus) throws {
        guard let arr = obj as? [[String: Any]] else {
            throw ParseError.invalidRootType
        }
        
        var result: [ItemType] = []
        for item in arr {
            let item: ItemType = try deserializer.deserialize(item)
            result.append(item)
        }
        
        fulfill(WebserviceResponse(data: result, headerFields: headers ?? [:],
            statusCode: statusCode))
    }
}



struct JSONDeserializer {

    private let deserializationContext: Any?
    
    init(deserializationContext: Any?) {
        self.deserializationContext = deserializationContext
    }
    
    func deserialize<T>(_ dict: [String: Any]) throws -> T {
        guard let clazz = T.self as? JSONConvertible.Type else {
            throw ParseError.missingJSONConvertibleConformance(
                givenClassName: String(describing: T.self))
        }
        
        let decoder = JSONDecoder(dict, className: String(describing: clazz),
            deserializer: self, deserializationContext: deserializationContext)
        return try clazz.init(decoder: decoder) as! T
    }
}
