//
//  ResponseHeadersTests.swift
//  NSMWebserviceTests
//
//  Created by Marc Bauer on 28.11.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

@testable import NSMWebservice

import XCTest

class ResponseHeadersTests: XCTestCase {
  func testCaseInsensitivity() {
    let headers = ResponseHeaders(headerFields: ["Content-Type": "application/json"])
    XCTAssertEqual(headers["Content-Type"], "application/json")
    XCTAssertEqual(headers["content-type"], "application/json")
  }

  func testExpiresHeader() {
    let components = DateComponents(
      timeZone: TimeZone(secondsFromGMT: 0),
      year: 2018,
      month: 11,
      day: 28,
      hour: 11,
      minute: 44,
      second: 09
    )

    XCTAssertEqual(
      ResponseHeaders(headerFields: ["Expires": "Wed, 28 Nov 2018 11:44:09 GMT"]).expires,
      Calendar.current.date(from: components)!
    )

    XCTAssertEqual(
      ResponseHeaders(headerFields: ["expires": "Wed, 28 Nov 2018 11:44:09 GMT"]).expires,
      Calendar.current.date(from: components)!
    )

    XCTAssertNil(ResponseHeaders(headerFields: [:]).expires)
  }

  func testDateHeader() {
    let components = DateComponents(
      timeZone: TimeZone(secondsFromGMT: 0),
      year: 2018,
      month: 11,
      day: 28,
      hour: 11,
      minute: 44,
      second: 09
    )

    XCTAssertEqual(
      ResponseHeaders(headerFields: ["Date": "Wed, 28 Nov 2018 11:44:09 GMT"]).date,
      Calendar.current.date(from: components)!
    )

    XCTAssertEqual(
      ResponseHeaders(headerFields: ["date": "Wed, 28 Nov 2018 11:44:09 GMT"]).date,
      Calendar.current.date(from: components)!
    )

    XCTAssertNil(ResponseHeaders(headerFields: [:]).date)
  }
}
