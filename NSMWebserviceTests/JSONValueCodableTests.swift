//
//  JSONValueCodableTests.swift
//  NSMWebserviceTests
//
//  Created by Marc Bauer on 27.04.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import NSMWebservice
import XCTest

public struct SingleValueBox<T: JSONValue>: Codable {
  public let value: T

  private enum CodingKeys: String, CodingKey {
    case value = "value"
  }

  init(_ value: T) {
    self.value = value
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.value = try container.ws_decode(T.self, forKey: .value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.ws_encode(self.value, forKey: .value)
  }
}

public struct OptionalSingleValueBox<T: JSONValue>: Codable {
  public let value: T?

  private enum CodingKeys: String, CodingKey {
    case value = "value"
  }

  init(_ value: T) {
    self.value = value
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.value = try container.ws_decodeIfPresent(T.self, forKey: .value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.ws_encodeIfPresent(self.value, forKey: .value)
  }
}


class JSONValueCodableTests: XCTestCase {
  func testInt() {
    let str = "{\"value\":123}"

    let res = try! WSJSONDecoder().decode(SingleValueBox<Int>.self, from: str.data(using: .utf8)!)
    XCTAssertEqual(res.value, 123)

    let data = try! WSJSONEncoder().encode(res)
    XCTAssertEqual(String(data: data, encoding: .utf8)!, str)
  }

  func testOptionalStringWithValue() {
    let str = "{\"value\":\"Hello World\"}"

    let res = try! WSJSONDecoder().decode(OptionalSingleValueBox<String>.self, from: str.data(using: .utf8)!)
    XCTAssertEqual(res.value, "Hello World")

    let data = try! WSJSONEncoder().encode(res)
    XCTAssertEqual(String(data: data, encoding: .utf8)!, str)
  }

func testOptionalStringWithoutValue() {
    let str = "{}"

    let res = try! WSJSONDecoder().decode(OptionalSingleValueBox<String>.self, from: str.data(using: .utf8)!)
    XCTAssertNil(res.value)

    let data = try! WSJSONEncoder().encode(res)
    XCTAssertEqual(String(data: data, encoding: .utf8)!, str)
  }
}
