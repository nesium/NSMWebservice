//
//  NSMWebserviceTests.swift
//  NSMWebserviceTests
//
//  Created by Marc Bauer on 30/12/2016.
//  Copyright © 2016 nesiumdotcom. All rights reserved.
//

import XCTest
import Swifter
import NSMWebservice
import RxSwift

class MyClass: Codable {
  public let a: String
  public let b: Int
  public let c: String?

  enum CodingKeys: String, CodingKey {
    case a
    case b
    case c
  }

  init(a: String, b: Int) {
    self.a = a
    self.b = b
    self.c = nil
  }
}

class MyContext {}

class NSMWebserviceTests: XCTestCase {

  private var session: Session!
  private var server: HttpServer!
  
  struct MethodCalled {
    var testPostObject: Bool = false
  }
  
  private var methodCalled = MethodCalled()
  
  override func setUp() {
    session = Session(
      baseURL: URL(string: "http://localhost:8889")!,
      gzipRequests: false
    )

    server = HttpServer()
    server["/testReturnString"] = { req in
      HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
        try $0.write([UInt8]("\"Hello World\"".utf8))
      }
    }
    server["/testSuccessfulDeserialization"] = { req in
      HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
        try $0.write([UInt8]("{\"a\": \"A\", \"b\": 123}".utf8))
      }
    }
    server["/testMissingAttribute"] = { req in
      HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
        try $0.write([UInt8]("{\"a\": \"A\"}".utf8))
      }
    }
    server["/testWrongAttributeType"] = { req in
      HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
        try $0.write([UInt8]("{\"a\": \"A\", \"b\": \"123\"}".utf8))
      }
    }
    server["/testArrayOfObjects"] = { req in
      HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
        try $0.write([UInt8]("[{\"a\": \"A\", \"b\": 123}, {\"a\": \"B\", \"b\": 456}]".utf8))
      }
    }
    server["/testPostObject"] = { [weak self] req in
      self?.methodCalled.testPostObject = true

      XCTAssertEqual(req.method, "POST")

      do {
        let obj = try JSONSerialization.jsonObject(
          with: Data(bytes: req.body), options: []) as! [String: Any]
        XCTAssertEqual(obj["a"] as! String, "AB")
        XCTAssertEqual(obj["b"] as! Int, 9999)
      } catch {
        XCTFail(error.localizedDescription)
        return HttpResponse.badRequest(nil)
      }

      return HttpResponse.ok(.text(""))
    }

    self.continueAfterFailure = false

    do {
      try self.server.start(8889)
    } catch {
      XCTFail(error.localizedDescription)
    }

    self.continueAfterFailure = true
  }

  override func tearDown() {
    server.stop()
  }

  func testStringAsRootObject() {
    let fetchExpectation = expectation(description: "Fetch Item")
    var responseReceived: Bool = false

    _ = session.request(String.self, .get("/testReturnString"))
      .subscribe(onSuccess: { result in
        XCTAssertEqual(result.data!, "Hello World")
        responseReceived = true
        fetchExpectation.fulfill()
      })

    waitForExpectations(timeout: 1)
    XCTAssertTrue(responseReceived)
  }

  func testSuccessfulDeserializationWithCallbackOnBackgroundThread() {
    let fetchExpectation = expectation(description: "Fetch Item")
    var responseReceived: Bool = false

    _ = session.request(MyClass.self, .get("/testSuccessfulDeserialization"))
      .subscribe(onSuccess: { result in
          XCTAssertFalse(Thread.isMainThread)
          XCTAssertEqual(result.data!.a, "A")
          XCTAssertEqual(result.data!.b, 123)
          responseReceived = true
          fetchExpectation.fulfill()
        })

    waitForExpectations(timeout: 1)
    XCTAssertTrue(responseReceived)
  }

  func testSuccessfulDeserializationWithCallbackOnMainThread() {
    let fetchExpectation = expectation(description: "Fetch Item")
    var responseReceived: Bool = false

    _ = session.request(MyClass.self, .get("/testSuccessfulDeserialization"))
      .observeOn(MainScheduler.instance)
      .subscribe(onSuccess: { result in
          XCTAssertTrue(Thread.isMainThread)
          XCTAssertEqual(result.data!.a, "A")
          XCTAssertEqual(result.data!.b, 123)
          responseReceived = true
          fetchExpectation.fulfill()
        })

    waitForExpectations(timeout: 1)
    XCTAssertTrue(responseReceived)
  }

  func testMissingAttribute() {
    let fetchExpectation = expectation(description: "Fetch Item")
    var responseReceived: Bool = false

    _ = session.request(MyClass.self, .get("/testMissingAttribute"))
      .subscribe(onSuccess: { result in
        XCTAssertNil(result.response)
        XCTAssertNotNil(result.error)
        print(result.error!)
        responseReceived = true
        fetchExpectation.fulfill()
      })

    waitForExpectations(timeout: 1)
    XCTAssertTrue(responseReceived)
  }

  func testWrongAttributeType() {
    let fetchExpectation = expectation(description: "Fetch Item")
    var responseReceived: Bool = false

    _ = session.request(MyClass.self, .get("/testWrongAttributeType"))
      .subscribe(onSuccess: { result in
        XCTAssertNil(result.response)
        XCTAssertNotNil(result.error)
        print(result.error!)
        responseReceived = true
        fetchExpectation.fulfill()
      })
      
    waitForExpectations(timeout: 1)
    XCTAssertTrue(responseReceived)
  }
  
  func testSuccessfulCollectionDeserialization() {
    let fetchExpectation = expectation(description: "Fetch Item")
    var responseReceived: Bool = false
    
    _ = session.request([MyClass].self, .get("/testArrayOfObjects"))
      .subscribe(onSuccess: { result in
        XCTAssertEqual(result.data!.count, 2)

        XCTAssertEqual(result.data![0].a, "A")
        XCTAssertEqual(result.data![0].b, 123)
        XCTAssertEqual(result.data![1].a, "B")
        XCTAssertEqual(result.data![1].b, 456)

        responseReceived = true
        fetchExpectation.fulfill()
      })

    waitForExpectations(timeout: 1)
    XCTAssertTrue(responseReceived)
  }

  func testPostObject() {
    let postExpectation = expectation(description: "Post Item")

    let obj = MyClass(a: "AB", b: 9999)
    var responseReceived: Bool = false

    _ = session.request(.post(obj, to: "/testPostObject"))
      .subscribe(onSuccess: { result in
        XCTAssertTrue(self.methodCalled.testPostObject)
        responseReceived = true
        postExpectation.fulfill()
      })

    waitForExpectations(timeout: 1)
    XCTAssertTrue(responseReceived)
  }
}
