//
//  WebserviceSession.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 09/01/2017.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation
import RxSwift

public enum HTTPMethod : String {
  case get    = "GET"
  case post   = "POST"
  case put    = "PUT"
  case delete = "DELETE"

  var hasBody: Bool {
    switch self {
      case .get, .delete:
        return false
      case .post, .put:
        return true
    }
  }
}



public struct WebserviceResponse<T> {
  public let data: T
  public let headerFields: [String: String]
  public let statusCode: HTTPStatus
}



public protocol WebserviceSession {
  var headerFields: [String: String] { get set }
  var gzipRequests: Bool { get set }

  init(baseURL: URL)

  func request(item: JSONConvertible?,
    path: String, parameters: [URLQueryItem]?,
    method: HTTPMethod, timeoutInterval: TimeInterval,
    deserializationContext: Any?) -> Observable<WebserviceResponse<Void>>

  func request(items: [JSONConvertible],
    path: String, parameters: [URLQueryItem]?,
    method: HTTPMethod, timeoutInterval: TimeInterval,
    deserializationContext: Any?) -> Observable<WebserviceResponse<Void>>

  func request<T: JSONCompatible>(_ cls: T.Type, item: JSONConvertible?,
    path: String, parameters: [URLQueryItem]?,
    method: HTTPMethod, timeoutInterval: TimeInterval,
    deserializationContext: Any?) -> Observable<WebserviceResponse<T>>

  func requestCollection<T: JSONCompatible>(_ cls: T.Type, item: JSONConvertible?,
    path: String, parameters: [URLQueryItem]?,
    method: HTTPMethod, timeoutInterval: TimeInterval,
    deserializationContext: Any?) -> Observable<WebserviceResponse<[T]>>

  func request<T: JSONCompatible>(_ cls: T.Type, items: [JSONConvertible],
    path: String, parameters: [URLQueryItem]?,
    method: HTTPMethod, timeoutInterval: TimeInterval,
    deserializationContext: Any?) -> Observable<WebserviceResponse<T>>
    
  func requestCollection<T: JSONCompatible>(_ cls: T.Type, items: [JSONConvertible],
    path: String, parameters: [URLQueryItem]?,
    method: HTTPMethod, timeoutInterval: TimeInterval,
    deserializationContext: Any?) -> Observable<WebserviceResponse<[T]>>
}
