//
//  Session.swift
//  Bookshelf
//
//  Created by Marc Bauer on 29.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation

public class Session {
    
    private let baseURL: URL
    private let session: URLSession
    
    private var registeredClasses: [String: JSONConvertible.Type] = [:]
    
    enum HTTPMethod : String {
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    init(baseURL: URL) {
        self.baseURL = baseURL
        self.session = URLSession(
            configuration: URLSessionConfiguration.default)
    }
    
    public func registerClass(_ clazz: JSONConvertible.Type) {
        registeredClasses[clazz.JSONClassName] = clazz
    }
    
    public func fetchItem<T>(path: String) -> ItemRequest<T> {
        let request = ItemRequest<T>(deserializer: deserializer())
        fetchDataWithRequest(path, request: request)
        return request
    }
    
    public func fetchCollection<T>(path: String) -> CollectionRequest<T> {
        let request = CollectionRequest<T>(deserializer: deserializer())
        fetchDataWithRequest(path, request: request)
        return request
    }
    
    public func saveItem(_ item: JSONConvertible, path: String) -> ItemRequest<Void> {
        return sendItem(item, path: path, method: .post)
    }
    
    public func updateItem<T>(_ item: JSONConvertible, path: String) -> ItemRequest<T> {
        return sendItem(item, path: path, method: .put)
    }
    
    public func deleteItem(path: String) -> ItemRequest<Void> {
        return sendItem(nil, path: path, method: .delete)
    }
    
    internal func sendItem<T>(_ item: JSONConvertible?, path: String,
        method: HTTPMethod) -> ItemRequest<T> {
        let request = ItemRequest<T>(deserializer: deserializer())
        let url = baseURL.appendingPathComponent(path)
        
        var urlRequest = URLRequest(url: url)
        
        if item != nil {
            do {
                urlRequest.httpBody = try JSONSerialization.data(
                    withJSONObject: item!.JSONObject(), options: [])
            } catch {}
        }
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpMethod = method.rawValue
        
        session.dataTask(with: urlRequest) { (data, response, error) -> Void in
            request.fulfill(data: data, response: response, error: error)
        }.resume()
        
        return request
    }
    
    private func fetchDataWithRequest<T: FulfillableRequest>(_ path: String, request: T) {
        let url = baseURL.appendingPathComponent(path)
        session.dataTask(with: url) { (data, response, error) -> Void in
            request.fulfill(data: data, response: response, error: error)
        }.resume()
    }
    
    private func deserializer<T>() -> ([String: Any]) throws -> T {
        return { [weak self] dict in
            guard let className = dict["__className"] as? String else {
                throw ParseError.missingClassName
            }
            
            guard let clazz = self?.registeredClasses[className] else {
                throw ParseError.unknownClassName(givenClassName: className)
            }
            
            return try clazz.init(json: dict) as! T
        }
    }
}


internal protocol FulfillableRequest: Request {
    var successHandlers: [(U) -> ()] { get }
    var failureHandlers: [(Error) -> ()] { get }

    func fulfill(data: Data?, response: URLResponse?, error: Error?)
    func fulfillWithJSONObject(_ obj: Any) throws
    func fulfill()
    func fail(_ error: Error)
}


extension FulfillableRequest {
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
        
        // Debug
        if let respStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
            print(respStr)
        }
        
        if U.self is Void.Type {
            fulfill()
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
            try fulfillWithJSONObject(obj)
        } catch let err {
            fail(err)
        }
    }
    
    func fail(_ error: Error) {
        let theErr: NSError
        
        if let err = error as? ParseError {
            let msg: String
            
            switch err {
                case .invalidRootType:
                    msg = "Invalid Root Type"
                case .invalidLeafType:
                    msg = "Invalid Leaf Type"
                case .missingClassName:
                    msg = "Missing Class Name"
                case .unexpectedResponse:
                    msg = "Unexpected Response"
                case .unknownClassName(_):
                    msg = "Invalid Class Name"
                case .missingFields(let className, let missingFields):
                    let joinedFields = missingFields.joined(separator: ", ")
                    msg = "Missing fields (\(joinedFields)) in class \(className)"
                case .formattingFailed(let errMsg):
                    msg = errMsg
            }
            
            theErr = NSError(
            	domain: "",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: msg]
            )
        } else {
            // http://stackoverflow.com/questions/32572033/casting-customnserror-to-errortype-to-nserror-loses-userinfo
            theErr = ((error as Any) as! NSError)
        }
        
        for handler in failureHandlers {
            DispatchQueue.main.async(execute: {
                handler(theErr)
            })
        }
    }
}


typealias ParameterlessCompletionHandler = () -> Void


extension ItemRequest {
    func fulfillWithJSONObject(_ obj: Any) throws {
        guard let dict = obj as? [String: Any] else {
            throw ParseError.invalidLeafType
        }
        let result: U = try deserializer(dict)
        for handler in successHandlers {
            DispatchQueue.main.async(execute: {
                handler(result)
            })
        }
    }
    
    func fulfill() {
        for handler in successHandlers {
            DispatchQueue.main.async(execute: { () -> Void in
                unsafeBitCast(handler, to: ParameterlessCompletionHandler.self)()
            })
        }
    }
}


extension CollectionRequest {
    func fulfillWithJSONObject(_ obj: Any) throws {
        guard let arr = obj as? [[String: Any]] else {
            throw ParseError.invalidRootType
        }
        
        var result: U = []
        for item in arr {
            try result.append(deserializer(item))
        }
        
        for handler in successHandlers {
            DispatchQueue.main.async(execute: {
                handler(result)
            })
        }
    }
    
    func fulfill() {
        assertionFailure()
    }
}
