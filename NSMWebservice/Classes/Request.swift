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

public struct Request<T> {
  public let method: HTTPMethod
  public let path: String
  public let data: T?
  public let parameters: [URLQueryItem]?
  public let headerFields: [String: String]?
  public let timeoutInterval: TimeInterval

  private let bodyDataEncoder: (T) throws -> Data?

  private init(
    _ method: HTTPMethod,
    _ path: String,
    data: T?,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30,
    bodyDataEncoder: @escaping (T) throws -> Data?) {
    self.method = method
    self.path = path
    self.data = data
    self.parameters = parameters
    self.headerFields = headerFields
    self.timeoutInterval = timeoutInterval
    self.bodyDataEncoder = bodyDataEncoder
  }

  public static func get(
    _ path: String,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30) -> Request<Void> {
    return Request<Void>(
      .get,
      path,
      data: nil,
      parameters: parameters,
      headerFields: headerFields,
      timeoutInterval: timeoutInterval
    ) { _ in nil }
  }

  public static func delete(
    _ path: String,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30) -> Request<Void> {
    return Request<Void>(
      .delete,
      path,
      data: nil,
      parameters: parameters,
      headerFields: headerFields,
      timeoutInterval: timeoutInterval
    ) { _ in nil }
  }

  public static func post(
    to path: String,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30) -> Request<Void> {
    return Request<Void>(
      .post,
      path,
      data: nil,
      parameters: parameters,
      headerFields: headerFields,
      timeoutInterval: timeoutInterval
    ) { _ in nil }
  }

  public static func post<T: Encodable & JSONValue>(
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
      timeoutInterval: timeoutInterval,
      bodyDataEncoder: JSONFragmentBodyEncoder
    )
  }

  public static func post<T: Encodable>(
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
      timeoutInterval: timeoutInterval,
      bodyDataEncoder: JSONBodyEncoder
    )
  }

  public static func put(
    to path: String,
    parameters: [URLQueryItem]? = nil,
    headerFields: [String: String]? = nil,
    timeoutInterval: TimeInterval = 30) -> Request<Void> {
    return Request<Void>(
      .put,
      path,
      data: nil,
      parameters: parameters,
      headerFields: headerFields,
      timeoutInterval: timeoutInterval
    ) { _ in nil }
  }

  public static func put<T: Encodable>(
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
      timeoutInterval: timeoutInterval,
      bodyDataEncoder: JSONBodyEncoder
    )
  }

  public static func put<T: Encodable & JSONValue>(
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
      timeoutInterval: timeoutInterval,
      bodyDataEncoder: JSONFragmentBodyEncoder
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
        if let data = self.data, let body = try self.bodyDataEncoder(data) {
          urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

          if gzip {
            urlRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            urlRequest.httpBody = try body.gzipped()
          } else {
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


fileprivate func JSONFragmentBodyEncoder<T: JSONValue>(_ object: T) throws -> Data? {
  let result: String

  switch object {
    case let value as Bool:
      result = value ? "true" : "false"

    case let value as Int:
      result = String(value)
    case let value as Int8:
      result = String(value)
    case let value as Int16:
      result = String(value)
    case let value as Int32:
      result = String(value)
    case let value as Int64:
      result = String(value)

    case let value as UInt:
      result = String(value)
    case let value as UInt8:
      result = String(value)
    case let value as UInt16:
      result = String(value)
    case let value as UInt32:
      result = String(value)
    case let value as UInt64:
      result = String(value)

    case let value as Double:
      result = String(value)
    case let value as Float:
      result = String(value)

    case let value as String:
      result = "\"\(value)\""
    case let value as Date:
      result = "\"\(ISO8601DateTimeTransformer.formatter.string(from: value))\""

    default:
      fatalError("Unexpected type \(String(describing: object))")
  }

  return result.data(using: .utf8)
}

fileprivate func JSONBodyEncoder<T: Encodable>(_ object: T) throws -> Data? {
  return try WSJSONEncoder().encode(object)
}
