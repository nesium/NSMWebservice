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
  public let headerFields: [String: String]
  public let statusCode: HTTPStatus
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
