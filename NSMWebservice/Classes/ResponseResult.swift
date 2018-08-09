//
//  ResponseResult.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 14.02.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import Foundation

public enum ResponseResult<T> {
  case success(Response<T>)
  case error(Error)

  public var response: Response<T>? {
    switch self {
      case .success(let response):
        return response
      case .error(_):
        return nil
    }
  }

  public var error: Error? {
    switch self {
      case .success(_):
        return nil
      case .error(let error):
        return error
    }
  }

  public var data: T? {
    return self.response?.data
  }

  public func map<U>(_ transform: (Response<T>) throws -> (U)) -> ResponseResult<U> {
    switch self {
      case let .success(response):
        do {
          return try .success(Response(
            data: transform(response),
            headerFields: response.headerFields,
            statusCode: response.statusCode
          ))
        } catch {
          return .error(error)
        }
      case let .error(err):
        return .error(err)
    }
  }

  public func mapHTTPError(_ transform: (HTTPError) -> Error) -> ResponseResult<T> {
    switch self {
      case let .error(error) where error is HTTPError:
        return .error(transform(error as! HTTPError))
      case .success, .error:
        return self
    }
  }
}

internal extension ResponseResult {
  init(urlResponse: URLResponse?, data: Data?, parser: ResponseParser<T>) throws {
    var headers: [String: String]? = nil
    var statusCode: HTTPStatus = .Ok

    if let httpResponse = urlResponse as? HTTPURLResponse {
      headers = httpResponse.allHeaderFields as? [String: String]
      statusCode = HTTPStatus(rawValue: httpResponse.statusCode) ?? .UnknownError
    }

    guard statusCode.isSuccess else {
      self = .error(HTTPError(
        headerFields: headers ?? [:],
        statusCode: statusCode,
        response: urlResponse,
        data: data
      ))
      return
    }

    self = .success(Response(
      data: try parser(data),
      headerFields: headers ?? [:],
      statusCode: statusCode
    ))
  }
}

typealias ResponseParser<T> = (Data?) throws -> T

