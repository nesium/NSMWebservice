//
//  NSMWebserviceTests.swift
//  NSMWebserviceTests
//
//  Created by Marc Bauer on 30/12/2016.
//  Copyright © 2016 nesiumdotcom. All rights reserved.
//

import XCTest
import Swifter
@testable import NSMWebservice
import PromiseKit

class MyClass: JSONConvertible {
    
    public let a: String
    public let b: Int
    
    static var JSONClassName: String {
        return "myclass"
    }
    
    init(a: String, b: Int) {
        self.a = a
        self.b = b
    }
    
    required init(json: [String : Any]) throws {
        guard let a = json["a"] as? String else {
            throw ParseError.missingField("a", cls: String(describing: MyClass.self))
        }
        
        guard let b = json["b"] as? Int else {
            throw ParseError.missingField("b", cls: String(describing: MyClass.self))
        }
        
        self.a = a
        self.b = b
    }
    
    func JSONObject() -> [String : Any] {
        return [
            "a": a,
            "b": b
        ]
    }
}

class NSMWebserviceTests: XCTestCase {
    
    private var session: Session!
    private var server: HttpServer!
    
    struct MethodCalled {
        var testPostObject: Bool = false
    }
    
    private var methodCalled = MethodCalled()
    
    override func setUp() {
        session = Session(baseURL: URL(string: "http://localhost:8889")!)
        session.registerClass(MyClass.self)
        
        server = HttpServer()
        server["/testSuccessfulDeserialization"] = { req in
            return HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
                try $0.write([UInt8]("{\"__classname\": \"myclass\", \"a\": \"A\", \"b\": 123}".utf8))
            }
        }
        server["/testMissingAttribute"] = { req in
            return HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
                try $0.write([UInt8]("{\"__classname\": \"myclass\", \"a\": \"A\"}".utf8))
            }
        }
        server["/testWrongAttributeType"] = { req in
            return HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
                try $0.write([UInt8]("{\"__classname\": \"myclass\", \"a\": \"A\", \"b\": \"123\"}".utf8))
            }
        }
        server["/testArrayOfObjects"] = { req in
            return HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
                try $0.write([UInt8]("[{\"__classname\": \"myclass\", \"a\": \"A\", \"b\": 123}, {\"__classname\": \"myclass\", \"a\": \"B\", \"b\": 456}]".utf8))
            }
        }
        server["/testPostObject"] = { [weak self] req in
            self?.methodCalled.testPostObject = true
            
            XCTAssertEqual(req.method, "POST")
            
            do {
                let obj = try JSONSerialization.jsonObject(
                	with: Data(bytes: req.body), options: []) as! [String: Any]
                XCTAssertEqual(obj["__classname"] as! String, "myclass")
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
    
    func testSuccessfulDeserialization() {
        let fetchExpectation = expectation(description: "Fetch Item")
        
        session.request(MyClass.self, path: "/testSuccessfulDeserialization")
        .then { resp -> Void in
            XCTAssertEqual(resp.data.a, "A")
            XCTAssertEqual(resp.data.b, 123)
            fetchExpectation.fulfill()
        }
        .catch { error in
            XCTFail(error.localizedDescription)
            fetchExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testMissingAttribute() {
        let fetchExpectation = expectation(description: "Fetch Item")
        
        session.request(MyClass.self, path: "/testMissingAttribute")
        .then { resp -> Void in
            XCTFail("Deserialization should fail")
            fetchExpectation.fulfill()
        }
        .catch { error in
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
        }
        
        waitForExpectations(timeout: 1)
    }

    func testWrongAttributeType() {
        let fetchExpectation = expectation(description: "Fetch Item")
        
        session.request(MyClass.self, path: "/testWrongAttributeType")
        .then { resp -> Void in
            XCTFail("Deserialization should fail")
            fetchExpectation.fulfill()
        }
        .catch { error in
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
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSuccessfulCollectionDeserialization() {
        let fetchExpectation = expectation(description: "Fetch Item")
        
        session.requestCollection(MyClass.self, path: "/testArrayOfObjects")
        .then { resp -> Void in
            XCTAssertEqual(resp.data.count, 2)
            
            XCTAssertEqual(resp.data[0].a, "A")
            XCTAssertEqual(resp.data[0].b, 123)
            XCTAssertEqual(resp.data[1].a, "B")
            XCTAssertEqual(resp.data[1].b, 456)
            
            fetchExpectation.fulfill()
        }
        .catch { error in
            XCTFail(error.localizedDescription)
            fetchExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testPostObject() {
        let postExpectation = expectation(description: "Post Item")
        
        let obj = MyClass(a: "AB", b: 9999)
        
        session.request(Void.self, item: obj, path: "/testPostObject", method: .post)
        .then { resp -> Void in
            XCTAssertTrue(self.methodCalled.testPostObject)
            postExpectation.fulfill()
        }
        .catch { error in
            XCTFail(error.localizedDescription)
            postExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}
