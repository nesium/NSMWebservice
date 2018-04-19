//
//  RequestTests.swift
//  NSMWebserviceTests
//
//  Created by Marc Bauer on 16.02.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

@testable import NSMWebservice
import XCTest
import SnapshotTesting

extension URLRequest {
  var snapshottableObject: [String: Any] {
    return [
      "url": self.url!.absoluteString,
      "method": self.httpMethod!,
      "timeoutInterval": self.timeoutInterval,
      "headerFields": self.allHTTPHeaderFields ?? [:],
      "httpBody": self.httpBody?.base64EncodedString() ?? ""
    ]
  }
}

class RequestTests: XCTestCase {
  func testGetRequest() {
    let req = Request<Void>.get(
      "/hello",
      parameters: [
        URLQueryItem(name: "a", value: "1"),
        URLQueryItem(name: "b", value: "2")
      ],
      headerFields: [
        "Authorization": "Bearer TOKEN",
        "X-My-Header": "Value"
      ],
      timeoutInterval: 10
    )

    assertSnapshot(matching: try! req.urlRequest(
      with: URL(string: "http://www.example.com")!, gzip: false).snapshottableObject)
  }

  func testDeleteRequest() {
    let req = Request<Void>.delete(
      "/hello",
      parameters: [
        URLQueryItem(name: "a", value: "1"),
        URLQueryItem(name: "b", value: "2")
      ],
      headerFields: [
        "Authorization": "Bearer TOKEN",
        "X-My-Header": "Value"
      ],
      timeoutInterval: 10
    )

    assertSnapshot(matching: try! req.urlRequest(
      with: URL(string: "http://www.example.com")!, gzip: false).snapshottableObject)
  }

  func testPostRequest() {
    let req = Request<[String]>.post(
      ["foo", "bar", "baz"],
      to: "/hello",
      parameters: [
        URLQueryItem(name: "a", value: "1"),
        URLQueryItem(name: "b", value: "2")
      ],
      headerFields: [
        "Authorization": "Bearer TOKEN",
        "X-My-Header": "Value"
      ],
      timeoutInterval: 10
    )

    assertSnapshot(matching: try! req.urlRequest(
      with: URL(string: "http://www.example.com")!, gzip: false).snapshottableObject)
  }

  func testEmptyPostRequest() {
    let req = Request<Void>.post(
      to: "/hello",
      parameters: [
        URLQueryItem(name: "a", value: "1"),
        URLQueryItem(name: "b", value: "2")
      ],
      headerFields: [
        "Authorization": "Bearer TOKEN",
        "X-My-Header": "Value"
      ],
      timeoutInterval: 10
    )

    assertSnapshot(matching: try! req.urlRequest(
      with: URL(string: "http://www.example.com")!, gzip: false).snapshottableObject)
  }

  func testPostRequestWithGzip() {
    let req = Request<[String]>.post(
      ["foo", "bar", "baz"],
      to: "/hello",
      parameters: [
        URLQueryItem(name: "a", value: "1"),
        URLQueryItem(name: "b", value: "2")
      ],
      headerFields: [
        "Authorization": "Bearer TOKEN",
        "X-My-Header": "Value"
      ],
      timeoutInterval: 10
    )

    assertSnapshot(matching: try! req.urlRequest(
      with: URL(string: "http://www.example.com")!, gzip: true).snapshottableObject)
  }

  func testPutRequest() {
    let req = Request<[String]>.put(
      ["foo", "bar", "baz"],
      to: "/hello",
      parameters: [
        URLQueryItem(name: "a", value: "1"),
        URLQueryItem(name: "b", value: "2")
      ],
      headerFields: [
        "Authorization": "Bearer TOKEN",
        "X-My-Header": "Value"
      ],
      timeoutInterval: 10
    )

    assertSnapshot(matching: try! req.urlRequest(
      with: URL(string: "http://www.example.com")!, gzip: false).snapshottableObject)
  }

  func testEmptyPutRequest() {
    let req = Request<Void>.put(
      to: "/hello",
      parameters: [
        URLQueryItem(name: "a", value: "1"),
        URLQueryItem(name: "b", value: "2")
      ],
      headerFields: [
        "Authorization": "Bearer TOKEN",
        "X-My-Header": "Value"
      ],
      timeoutInterval: 10
    )

    assertSnapshot(matching: try! req.urlRequest(
      with: URL(string: "http://www.example.com")!, gzip: false).snapshottableObject)
  }

  func testDateFragmentEncoding() {
    let req = Request<Date>.post(
      Date(timeIntervalSinceReferenceDate: 100000.123),
      to: "/hello"
    )

    assertSnapshot(matching: try! req.urlRequest(
      with: URL(string: "http://www.example.com")!, gzip: false).snapshottableObject)
  }

  func testDateEncoding() {
    let req = Request<[Date]>.post(
      [Date(timeIntervalSinceReferenceDate: 100000.123)],
      to: "/hello"
    )

    assertSnapshot(matching: try! req.urlRequest(
      with: URL(string: "http://www.example.com")!, gzip: false).snapshottableObject)
  }

}
