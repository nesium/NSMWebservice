//
//  Session.swift
//  Bookshelf
//
//  Created by Marc Bauer on 29.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation
import PromiseKit

internal let classNameKey = "__classname"

public struct WebserviceResponse<T> {
    public let data: T
    public let headerFields: [String: String]
}

public class Session {
    
    private let baseURL: URL
    private let session: URLSession
    private var registeredClasses: [String: JSONConvertible.Type] = [:]
    
    public enum HTTPMethod : String {
        case get    = "GET"
        case post   = "POST"
        case put    = "PUT"
        case delete = "DELETE"
    }
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.session = URLSession(
            configuration: URLSessionConfiguration.default)
    }
    
    public func registerClass(_ clazz: JSONConvertible.Type) {
        registeredClasses[clazz.JSONClassName] = clazz
    }
       
    @discardableResult public func request<T>(_ cls: T.Type, item: JSONConvertible? = nil,
        path: String, method: HTTPMethod = .get,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<T>> {
        let deserializer = JSONDeserializer(
            registeredClasses: registeredClasses,
            deserializationContext: deserializationContext)
        let promise: ItemPromise<T> = ItemPromise(deserializer: deserializer)
        performRequest(with: promise, item: item, path: path, method: method)
        return promise
    }
    
    @discardableResult public func requestCollection<T>(_ cls: T.Type, item: JSONConvertible? = nil,
        path: String, method: HTTPMethod = .get,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<[T]>> {
        let deserializer = JSONDeserializer(
            registeredClasses: registeredClasses,
            deserializationContext: deserializationContext)
        let promise: CollectionPromise<T> = CollectionPromise(deserializer: deserializer)
        performRequest(with: promise, item: item, path: path, method: method)
        return promise
    }
    
    @discardableResult public func request<T>(_ cls: T.Type, items: [JSONConvertible],
        path: String, method: HTTPMethod = .get,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<T>> {
        let deserializer = JSONDeserializer(
            registeredClasses: registeredClasses,
            deserializationContext: deserializationContext)
        let promise: ItemPromise<T> = ItemPromise(deserializer: deserializer)
        performRequest(with: promise, items: items, path: path, method: method)
        return promise
    }
    
    @discardableResult public func requestCollection<T>(_ cls: T.Type, items: [JSONConvertible],
        path: String, method: HTTPMethod = .get,
        deserializationContext: Any? = nil) -> Promise<WebserviceResponse<[T]>> {
        let deserializer = JSONDeserializer(
            registeredClasses: registeredClasses,
            deserializationContext: deserializationContext)
        let promise: CollectionPromise<T> = CollectionPromise(deserializer: deserializer)
        performRequest(with: promise, items: items, path: path, method: method)
        return promise
    }
    
    private func performRequest<ItemType, ResultType>(
        with promise: WebservicePromise<ItemType, ResultType>, item: JSONConvertible? = nil,
        path: String, method: HTTPMethod) {
        var urlRequest = requestWithPath(path: path, method: method)
        
        if item != nil {
            do {
                urlRequest.httpBody = try JSONSerialization.data(
                    withJSONObject: try item!.JSONObjectIncludingClassName(), options: [])
            } catch {
                promise.fail(error)
                return
            }
        }
        
        perform(request: urlRequest, promise: promise)
    }
    
    private func performRequest<ItemType, ResultType>(
        with promise: WebservicePromise<ItemType, ResultType>, items: [JSONConvertible],
        path: String, method: HTTPMethod) {
        var urlRequest = requestWithPath(path: path, method: method)
        
        do {
            let jsonItems = try items.map { item in
                return try item.JSONObjectIncludingClassName()
            }
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: jsonItems, options: [])
        } catch {
            promise.fail(error)
            return
        }
        
        perform(request: urlRequest, promise: promise)
    }
    
    private func requestWithPath(path: String, method: HTTPMethod) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var urlRequest = URLRequest(url: url)
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
        
        guard statusCode.isSuccess() else {
            let httpError = NSError(
            	domain: "ServerDomain",
                code: statusCode.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "The request failed. " +
                    "The server responded with status code \(statusCode.description)."])
            fail(httpError)
            return
        }
        
        // Debug
        if let respStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
            print(respStr)
        }
        
        if ResultType.self is Void.Type {
            fulfill(WebserviceResponse(
                data: () as! ResultType,
                headerFields: headers ?? [:]))
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
            try fulfillWithJSONObject(obj, headers: headers)
        } catch let err {
            fail(err)
        }
    }
    
    func fail(_ error: Error) {
        reject(error)
    }
    
    func fulfillWithJSONObject(_ obj: Any, headers: [String: String]?) throws {
        fatalError("fulfillWithJSONObject must be implemented in a subclass")
    }
}



fileprivate class ItemPromise<ItemType>: WebservicePromise<ItemType, ItemType> {
    
    override func fulfillWithJSONObject(_ obj: Any, headers: [String: String]?) throws {
        guard let dict = obj as? [String: Any] else {
            throw ParseError.invalidLeafType
        }
        let result: ItemType = try deserializer.deserialize(dict)
        fulfill(WebserviceResponse(data: result, headerFields: headers ?? [:]))
    }
}



fileprivate class CollectionPromise<ItemType>: WebservicePromise<ItemType, [ItemType]> {

    override func fulfillWithJSONObject(_ obj: Any, headers: [String: String]?) throws {
        guard let arr = obj as? [[String: Any]] else {
            throw ParseError.invalidRootType
        }
        
        var result: [ItemType] = []
        for item in arr {
            let item: ItemType = try deserializer.deserialize(item)
            result.append(item)
        }
        
        fulfill(WebserviceResponse(data: result, headerFields: headers ?? [:]))
    }
}



struct JSONDeserializer {

    private let registeredClasses: [String: JSONConvertible.Type]
    private let deserializationContext: Any?
    
    init(registeredClasses: [String: JSONConvertible.Type], deserializationContext: Any?) {
        self.registeredClasses = registeredClasses
        self.deserializationContext = deserializationContext
    }
    
    func deserialize<T>(_ dict: [String: Any]) throws -> T {
        guard let className = dict[classNameKey] as? String else {
            throw ParseError.missingClassName
        }
        
        guard let clazz = self.registeredClasses[className] else {
            throw ParseError.unknownClassName(givenClassName: className)
        }
        
        let decoder = JSONDecoder(dict, className: String(describing: clazz),
            deserializer: self, deserializationContext: deserializationContext)
        return try clazz.init(decoder: decoder) as! T
    }
}
