//
//  Request.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 14.02.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import Foundation

public enum HTTPMethod : String {
  case get    = "GET"
  case post   = "POST"
  case put    = "PUT"
  case delete = "DELETE"

  internal var hasBody: Bool {
    switch self {
      case .get, .delete:
        return false
      case .post, .put:
        return true
    }
  }
}

public struct Request<T: Encodable> {
  public var method: HTTPMethod
  public var path: String
  public var data: T?
  public var parameters: [URLQueryItem]?
  public var headerFields: [String: String]?
  public var timeoutInterval: TimeInterval

  private init(
    _ method: HTTPMethod,
    _ path: String,
    data: T?,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30) {
    self.method = method
    self.path = path
    self.data = data
    self.parameters = parameters
    self.headerFields = headerFields
    self.timeoutInterval = timeoutInterval
  }

  public static func get(
    _ path: String,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30) -> Request<Empty> {
    return Request<Empty>(
      .get,
      path,
      data: nil,
      parameters: parameters,
      headerFields: headerFields,
      timeoutInterval: timeoutInterval
    )
  }

  public static func post<T>(
    _ data: T?,
    to path: String,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30) -> Request<T> {
    return Request<T>(
      .post,
      path,
      data: data,
      parameters: parameters,
      headerFields: headerFields,
      timeoutInterval: timeoutInterval
    )
  }

  public static func put<T>(
    _ data: T?,
    to path: String,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30) -> Request<T> {
    return Request<T>(
      .put,
      path,
      data: data,
      parameters: parameters,
      headerFields: headerFields,
      timeoutInterval: timeoutInterval
    )
  }

  public static func delete(
    _ path: String,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30) -> Request<Empty> {
    return Request<Empty>(
      .delete,
      path,
      data: nil,
      parameters: parameters,
      headerFields: headerFields,
      timeoutInterval: timeoutInterval
    )
  }
}

internal extension Request {
  func urlRequest(with baseURL: URL, gzip: Bool) throws -> URLRequest {
    var url = baseURL.appendingPathComponent(self.path)

    if let parameters = self.parameters, !parameters.isEmpty {
      var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
      urlComponents.queryItems = parameters
      url = urlComponents.url!
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.timeoutInterval = self.timeoutInterval

    self.headerFields?.forEach({ (key, value) in
      urlRequest.setValue(value, forHTTPHeaderField: key)
    })

    switch self.method {
      case .post, .put:
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let data = self.data {
          let coder = JSONEncoder()
          let body = try coder.encode(data)

          switch gzip {
            case true:
              urlRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
              urlRequest.httpBody = body
            case false:
              urlRequest.httpBody = body
          }
        }

      case .get, .delete:
        break
    }

    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    urlRequest.httpMethod = self.method.rawValue

    return urlRequest
  }
}
