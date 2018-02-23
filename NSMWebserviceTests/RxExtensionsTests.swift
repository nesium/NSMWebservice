//
//  RxExtensionsTests.swift
//  NSMWebserviceTests
//
//  Created by Marc Bauer on 23.02.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import Foundation
@testable import NSMWebservice
import RxSwift
import XCTest

class RxExtensionsTests: XCTestCase {
  func testMapToThrowingObservableSuccess() {
    let result = Result.success(Response(data: "ABC", headerFields: [:], statusCode: .Ok))
    let observable = Single.just(result)

    let exp = expectation(description: "Waiting…")

    var receivedData: String?

    _ = observable
      .mapToThrowingObservable()
      .subscribe(
        onNext: {
          receivedData = $0.data
        },
        onError: { _ in
          XCTFail()
        },
        onCompleted: {
          XCTAssertEqual(receivedData, "ABC")
          exp.fulfill()
        }
      )

    waitForExpectations(timeout: 1)
  }

  func testMapToThrowingObservableError() {
    let result = Result<String>.error(NSError(
      domain: "TestDomain",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: "TestError"]
    ))
    let observable = Single.just(result)

    let exp = expectation(description: "Waiting…")

    _ = observable
      .mapToThrowingObservable()
      .subscribe(
        onNext: { _ in
          XCTFail()
        },
        onError: { error in
          XCTAssertEqual(error.localizedDescription, "TestError")
          exp.fulfill()
        },
        onCompleted: {
          XCTFail()
        }
      )

    waitForExpectations(timeout: 1)
  }
}
