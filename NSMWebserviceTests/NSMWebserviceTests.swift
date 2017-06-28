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

class MyClass: JSONConvertible {
  public let a: String
  public let b: Int
  public let c: String?

  init(a: String, b: Int) {
    self.a = a
    self.b = b
    self.c = nil
  }

  required init(decoder: NSMWebservice.JSONDecoder) throws {
    self.a = try decoder.decode("a")
    self.b = try decoder.decode("b")
    self.c = try decoder.decode("c")

    XCTAssert(decoder.deserializationContext is MyContext)
  }

  func encode(encoder: NSMWebservice.JSONEncoder) throws {
    try encoder.encode("a", a)
    try encoder.encode("b", b)
    try encoder.encode("c", c)
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
    session = Session(baseURL: URL(string: "http://localhost:8889")!)
    session.gzipRequests = false

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

    _ = session.request(String.self, path: "/testReturnString",
      deserializationContext: MyContext()).subscribe(
        onNext: { resp in
          XCTAssertEqual(resp.data, "Hello World")
          responseReceived = true
        },
        onError: { error in
          XCTFail(error.localizedDescription)
          fetchExpectation.fulfill()
        },
        onCompleted: {
          XCTAssertTrue(responseReceived)
          fetchExpectation.fulfill()
        })

    waitForExpectations(timeout: 1)
  }

  func testSuccessfulDeserializationWithCallbackOnBackgroundThread() {
    let fetchExpectation = expectation(description: "Fetch Item")
    var responseReceived: Bool = false

    _ = session.request(MyClass.self, path: "/testSuccessfulDeserialization",
      deserializationContext: MyContext()).subscribe(
        onNext: { resp in
          XCTAssertFalse(Thread.isMainThread)
          XCTAssertEqual(resp.data.a, "A")
          XCTAssertEqual(resp.data.b, 123)
          responseReceived = true
        },
        onError: { error in
          XCTFail(error.localizedDescription)
          fetchExpectation.fulfill()
        },
        onCompleted: {
          XCTAssertFalse(Thread.isMainThread)
          XCTAssertTrue(responseReceived)
          fetchExpectation.fulfill()
        })

    waitForExpectations(timeout: 1)
  }

  func testSuccessfulDeserializationWithCallbackOnMainThread() {
    let fetchExpectation = expectation(description: "Fetch Item")
    var responseReceived: Bool = false

    _ = session.request(MyClass.self, path: "/testSuccessfulDeserialization",
      deserializationContext: MyContext())
      .observeOn(MainScheduler.instance)
      .subscribe(
        onNext: { resp in
          XCTAssertTrue(Thread.isMainThread)
          XCTAssertEqual(resp.data.a, "A")
          XCTAssertEqual(resp.data.b, 123)
          responseReceived = true
        },
        onError: { error in
          XCTFail(error.localizedDescription)
          fetchExpectation.fulfill()
        },
        onCompleted: {
          XCTAssertTrue(Thread.isMainThread)
          XCTAssertTrue(responseReceived)
          fetchExpectation.fulfill()
        })

    waitForExpectations(timeout: 1)
  }

  func testActivityIndicator() {
    let fetchExpectation = expectation(description: "Fetch Items")

    let req1 = session.request(MyClass.self, path: "/testSuccessfulDeserialization",
        deserializationContext: MyContext())
    	.delay(0.2, scheduler: MainScheduler.instance)
      .map { _ in 0 }
    let req2 = session.request(MyClass.self, path: "/testSuccessfulDeserialization",
        deserializationContext: MyContext())
      .delay(0.5, scheduler: MainScheduler.instance)
      .map { _ in 1 }
    var onNextCalled: Int = 0
    var onCompletedCalled: Bool = false

    _ = Observable.zip(Observable.merge(req1, req2),
    	ActivityIndicator.shared.asSharedSequence().asObservable().take(2))
      .subscribe(
        onNext: { value in
          switch value {
            case (0, let isLoading):
              XCTAssertTrue(isLoading)
            case (1, let isLoading):
              XCTAssertFalse(isLoading)
            default:
              XCTFail("Unknown state")
          }
          onNextCalled += 1
        },
        onError: { error in
          XCTFail(error.localizedDescription)
          fetchExpectation.fulfill()
        },
        onCompleted: {
          onCompletedCalled = true
        },
        onDisposed: {
          XCTAssertEqual(onNextCalled, 2)
          XCTAssertTrue(onCompletedCalled)
          fetchExpectation.fulfill()
        })

    waitForExpectations(timeout: 1)
  }

  func testMissingAttribute() {
    let fetchExpectation = expectation(description: "Fetch Item")

    _ = session.request(MyClass.self, path: "/testMissingAttribute").subscribe(
      onNext: { resp -> Void in
        XCTFail("Deserialization should fail")
        fetchExpectation.fulfill()
      },
      onError: { error in
        guard let err = error as? ParseError else {
          XCTFail("Error should be a ParseError")
          fetchExpectation.fulfill()
          return
        }

        switch err {
          case .missingField(let field, let cls):
            XCTAssertEqual(field, "b")
            XCTAssertEqual(cls, "MyClass")
            break
          default:
            XCTFail("Error should be of type .missingField")
        }
        fetchExpectation.fulfill()
      })

    waitForExpectations(timeout: 1)
  }

  func testWrongAttributeType() {
    let fetchExpectation = expectation(description: "Fetch Item")

    _ = session.request(MyClass.self, path: "/testWrongAttributeType",
      deserializationContext: MyContext()).subscribe(
      onNext: { resp -> Void in
        XCTFail("Deserialization should fail")
        fetchExpectation.fulfill()
      },
      onError: { error in
        guard let err = error as? ParseError else {
          XCTFail("Error should be a ParseError")
          fetchExpectation.fulfill()
          return
        }

        switch err {
          case .incorrectFieldType(let field, let expectedType, let foundType, let cls):
            XCTAssertEqual(field, "b")
            XCTAssertEqual(expectedType, "Int")
            XCTAssertEqual(foundType, "NSTaggedPointerString")
            XCTAssertEqual(cls, "MyClass")
            break
          default:
            XCTFail("Error should be of type .incorrectFieldType")
        }

        fetchExpectation.fulfill()
      })
      
    waitForExpectations(timeout: 1)
  }
  
  func testSuccessfulCollectionDeserialization() {
    let fetchExpectation = expectation(description: "Fetch Item")
    var responseReceived: Bool = false
    
    _ = session.requestCollection(MyClass.self, path: "/testArrayOfObjects",
      deserializationContext: MyContext()).subscribe(
    onNext: { resp -> Void in
      XCTAssertEqual(resp.data.count, 2)

      XCTAssertEqual(resp.data[0].a, "A")
      XCTAssertEqual(resp.data[0].b, 123)
      XCTAssertEqual(resp.data[1].a, "B")
      XCTAssertEqual(resp.data[1].b, 456)

      responseReceived = true
    },
    onError: { error in
      XCTFail(error.localizedDescription)
      fetchExpectation.fulfill()
    },
    onCompleted: {
      XCTAssertTrue(responseReceived)
      fetchExpectation.fulfill()
    })

    waitForExpectations(timeout: 1)
  }

  func testPostObject() {
    let postExpectation = expectation(description: "Post Item")

    let obj = MyClass(a: "AB", b: 9999)
    var responseReceived: Bool = false

    _ = session.request(item: obj, path: "/testPostObject", method: .post,
      deserializationContext: MyContext()).subscribe(
        onNext: { resp -> Void in
          XCTAssertTrue(self.methodCalled.testPostObject)
          responseReceived = true
        },
        onError: { error in
          XCTFail(error.localizedDescription)
          postExpectation.fulfill()
        },
        onCompleted: {
          XCTAssertTrue(responseReceived)
          postExpectation.fulfill()
        })

    waitForExpectations(timeout: 1)
  }
}
