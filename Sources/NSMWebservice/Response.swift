//
//  Response.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 14.02.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import Foundation

public struct Response<T> {
  public let data: T
  public let headerFields: ResponseHeaders
  public let statusCode: HTTPStatus

  public init(data: T, headerFields: [String: String], statusCode: HTTPStatus) {
    self.data = data
    self.headerFields = ResponseHeaders(headerFields: headerFields)
    self.statusCode = statusCode
  }

  public init(data: T, responseHeaders: ResponseHeaders, statusCode: HTTPStatus) {
    self.data = data
    self.headerFields = responseHeaders
    self.statusCode = statusCode
  }
}

public enum ResponseError: LocalizedError, CustomStringConvertible {
  case emptyResponse
  case unexpectedType

  public var description: String {
    switch self {
      case .emptyResponse:
        return "The server did not return data."
      case .unexpectedType:
        return "The server returned an invalid response."
    }
  }

  public var errorDescription: String? {
    return self.description
  }
}

public struct ResponseHeaders {
  private let headerFields: [String: String]

  internal init(headerFields: [String: String]) {
    self.headerFields = headerFields.reduce(into: [String: String]()) { result, nextPair in
      result[nextPair.key.lowercased()] = nextPair.value
    }
  }

  public subscript(_ name: String) -> String? {
    return self.headerFields[name.lowercased()]
  }

  public var expires: Date? {
    return self.headerFields["expires"].map(httpDateFormatter.date) ?? nil
  }

  public var date: Date? {
    return self.headerFields["date"].map(httpDateFormatter.date) ?? nil
  }
}


private let httpDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  return formatter
}()

private func dateFrom(httpDate: String) -> Date? {
  return httpDateFormatter.date(from: httpDate)
}
