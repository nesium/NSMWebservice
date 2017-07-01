//
//  Session.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 29.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation
import RxSwift

final public class Session: WebserviceSession {

  private let baseURL: URL
  private let session: URLSession

  public var headerFields: [String: String] = [:]
  public var gzipRequests: Bool = true

  public init(baseURL: URL) {
    self.baseURL = baseURL
    self.session = URLSession(configuration: URLSessionConfiguration.default)
  }

  public func request(item: JSONConvertible? = nil,
    path: String, parameters: [URLQueryItem]? = nil,
    method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
    deserializationContext: Any? = nil) -> Observable<WebserviceResponse<Void>> {
    let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
    let promise: ItemPromise<Void> = ItemPromise(deserializer: deserializer)
    self.performRequest(with: promise, item: item, path: path, parameters: parameters,
      method: method, timeoutInterval: timeoutInterval)
    return self.observable(with: promise)
  }
    
  public func request(items: [JSONConvertible], path: String, parameters: [URLQueryItem]? = nil,
    method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
    deserializationContext: Any? = nil) -> Observable<WebserviceResponse<Void>> {
    let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
    let promise: ItemPromise<Void> = ItemPromise(deserializer: deserializer)
    self.performRequest(with: promise, items: items, path: path, parameters: parameters,
      method: method, timeoutInterval: timeoutInterval)
    return self.observable(with: promise)
  }

  public func request<T: JSONCompatible>(_ cls: T.Type, item: JSONConvertible? = nil,
    path: String, parameters: [URLQueryItem]? = nil, method: HTTPMethod = .get,
    timeoutInterval: TimeInterval = 30,
    deserializationContext: Any? = nil) -> Observable<WebserviceResponse<T>> {
    let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
    let promise: ItemPromise<T> = ItemPromise(deserializer: deserializer)
    self.performRequest(with: promise, item: item, path: path, parameters: parameters,
      method: method, timeoutInterval: timeoutInterval)
    return self.observable(with: promise)
  }

  public func requestCollection<T: JSONCompatible>(_ cls: T.Type, item: JSONConvertible? = nil,
    path: String, parameters: [URLQueryItem]? = nil,
    method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
    deserializationContext: Any? = nil) -> Observable<WebserviceResponse<[T]>> {
    let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
    let promise: CollectionPromise<T> = CollectionPromise(deserializer: deserializer)
    self.performRequest(with: promise, item: item, path: path, parameters: parameters,
      method: method, timeoutInterval: timeoutInterval)
    return self.observable(with: promise)
  }

  public func request<T: JSONCompatible>(_ cls: T.Type, items: [JSONConvertible],
    path: String, parameters: [URLQueryItem]? = nil,
    method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
    deserializationContext: Any? = nil) -> Observable<WebserviceResponse<T>> {
    let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
    let promise: ItemPromise<T> = ItemPromise(deserializer: deserializer)
    self.performRequest(with: promise, items: items, path: path, parameters: parameters,
      method: method, timeoutInterval: timeoutInterval)
    return self.observable(with: promise)
  }

  public func requestCollection<T: JSONCompatible>(_ cls: T.Type, items: [JSONConvertible],
    path: String, parameters: [URLQueryItem]? = nil,
    method: HTTPMethod = .get, timeoutInterval: TimeInterval = 30,
    deserializationContext: Any? = nil) -> Observable<WebserviceResponse<[T]>> {
    let deserializer = JSONDeserializer(deserializationContext: deserializationContext)
    let promise: CollectionPromise<T> = CollectionPromise(deserializer: deserializer)
    self.performRequest(with: promise, items: items, path: path, parameters: parameters,
      method: method, timeoutInterval: timeoutInterval)
    return self.observable(with: promise)
  }

  private func performRequest<ItemType, ResultType>(
    with promise: WebservicePromise<ItemType, ResultType>, item: JSONConvertible? = nil,
    path: String, parameters: [URLQueryItem]?, method: HTTPMethod, timeoutInterval: TimeInterval) {
    var urlRequest = requestWithPath(path: path, parameters: parameters, method: method,
      timeoutInterval: timeoutInterval)

    if method.hasBody {
      // TODO: Perform serialization on background thread
      if let item = item {
        do {
          let data = try JSONSerialization.data(withJSONObject: try item.JSONObject(), options: [])
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
    path: String, parameters: [URLQueryItem]?, method: HTTPMethod, timeoutInterval: TimeInterval) {
    var urlRequest = requestWithPath(path: path, parameters: parameters, method: method,
      timeoutInterval: timeoutInterval)

    if method.hasBody {
      // TODO: Perform serialization on background thread
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

  private func requestWithPath(path: String, parameters: [URLQueryItem]?,
    method: HTTPMethod, timeoutInterval: TimeInterval) -> URLRequest {
    var url = baseURL.appendingPathComponent(path)

    if parameters != nil, parameters!.count > 0 {
      var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
      urlComponents.queryItems = parameters
      url = urlComponents.url!
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.timeoutInterval = timeoutInterval

    headerFields.forEach { (arg) in
      let (key, value) = arg
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
    let dataTask = session.dataTask(with: request) { (data, response, error) -> Void in
      promise.fulfill(data: data, response: response, error: error)
    }
    promise.dataTask = dataTask
  }

  private func append(data: Data, to urlRequest: inout URLRequest) throws {
    if gzipRequests {
      urlRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
      urlRequest.httpBody = try data.gzipped()
    } else {
      urlRequest.httpBody = data
    }
  }

  private func observable<ItemType, ResultType>(
    with promise: WebservicePromise<ItemType, ResultType>) ->
    Observable<WebserviceResponse<ResultType>> {
    return Observable.create { observer in
      promise.observer = observer
      promise.dataTask.resume()
      return Disposables.create(with: promise.cancel)
    }.trackActivity(ActivityIndicator.shared)
  }
}



fileprivate class WebservicePromise<ItemType, ResultType> {
  fileprivate let deserializer: JSONDeserializer
  
  fileprivate weak var dataTask: URLSessionDataTask!
  fileprivate var observer: AnyObserver<WebserviceResponse<ResultType>>!
  
  fileprivate init(deserializer: JSONDeserializer) {
    self.deserializer = deserializer
  }
  
  fileprivate func fulfill(data: Data?, response: URLResponse?, error: Error?) {
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
      self.fulfill(WebserviceResponse(
        data: () as! ResultType,
        headerFields: headers ?? [:],
        statusCode: statusCode))
      return
    }

    let obj: Any
    do {
      assert(!Thread.isMainThread)
      try obj = JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
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

  fileprivate func fail(_ error: Error) {
    self.observer.on(.error(error))
  }

  fileprivate func fulfillWithJSONObject(_ obj: Any, headers: [String: String]?,
    statusCode: HTTPStatus) throws {
    fatalError("fulfillWithJSONObject must be implemented in a subclass")
  }

  fileprivate func fulfill(_ response: WebserviceResponse<ResultType>) {
    self.observer.on(.next(response))
    self.observer.on(.completed)
  }

  fileprivate func cancel() {
    self.dataTask?.cancel()
  }
}



fileprivate class ItemPromise<ItemType>: WebservicePromise<ItemType, ItemType> {
  override func fulfillWithJSONObject(_ obj: Any, headers: [String: String]?,
    statusCode: HTTPStatus) throws {
    let result: ItemType
    switch obj {
      case let dict as [String: Any]:
        result = try deserializer.deserialize(dict)
      case let item as ItemType:
        result = item
      default:
        throw ParseError.invalidRootType
    }

    self.fulfill(WebserviceResponse(
      data: result,
      headerFields: headers ?? [:],
      statusCode: statusCode))
  }
}



fileprivate class CollectionPromise<ItemType>: WebservicePromise<ItemType, [ItemType]> {
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

    self.fulfill(WebserviceResponse(
      data: result,
      headerFields: headers ?? [:],
      statusCode: statusCode))
  }
}



internal struct JSONDeserializer {
  private let deserializationContext: Any?

  internal init(deserializationContext: Any?) {
    self.deserializationContext = deserializationContext
  }

  internal func deserialize<T>(_ dict: [String: Any]) throws -> T {
    guard let clazz = T.self as? JSONConvertible.Type else {
      throw ParseError.missingJSONConvertibleConformance(
        givenClassName: String(describing: T.self))
    }

    let decoder = JSONDecoder(dict, className: String(describing: clazz),
      deserializer: self, deserializationContext: deserializationContext)
    return try clazz.init(decoder: decoder) as! T
  }

  internal func deserialize<T>(_ data: Data) throws -> T {
    guard let dict =
      try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      throw ParseError.invalidRootType
    }
    return try self.deserialize(dict)
  }
}
