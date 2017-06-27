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

  public var description: String {
    return "The request failed. The server responded with status code \(statusCode.description)."
  }

  public var errorDescription: String? {
    return self.description
  }
}
