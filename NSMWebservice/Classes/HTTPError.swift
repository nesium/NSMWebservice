//
//  HTTPError.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 20.04.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation

public struct HTTPError: LocalizedError, CustomStringConvertible {
  public let headerFields: [String: String]
  public let statusCode: HTTPStatus
  public let response: URLResponse?
  public let data: Data?

  public init(
    headerFields: [String: String],
    statusCode: HTTPStatus,
    response: URLResponse?,
    data: Data?
  ) {
    self.headerFields = headerFields
    self.statusCode = statusCode
    self.response = response
    self.data = data
  }

  public var description: String {
    return "The request failed. The server responded with status code \(statusCode.description)."
  }

  public var errorDescription: String? {
    return self.description
  }

  public func decodedData<T: Decodable>() throws -> T {
    return try JSONResponseParser(self.data)
  }
}
