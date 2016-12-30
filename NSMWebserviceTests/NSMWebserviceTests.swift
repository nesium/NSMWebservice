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

class MyClass: JSONConvertible {
    
    public let a: String
    public let b: Int
    
    static var JSONClassName: String {
        return "myclass"
    }
    
    required init(json: [String : Any]) throws {
        a = json["a"] as! String
        b = json["b"] as! Int
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
    
    override func setUp() {
        session = Session(baseURL: URL(string: "http://localhost:8889")!)
        session.registerClass(MyClass.self)
        
        server = HttpServer()
        server["/hello"] = { req in
            return HttpResponse.raw(200, "OK", ["Content-Type": "application/json"]) {
                try $0.write([UInt8]("{\"__className\": \"myclass\", \"a\": \"A\", \"b\": 123}".utf8))
            }
        }
        
        do {
            try self.server.start(8889)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    override func tearDown() {
        server.stop()
    }
    
    func testDeserialization() {
        let fetchExpectation = expectation(description: "Fetch Item")
        
        let req: ItemRequest<MyClass> = session.fetchItem(path: "/hello")
        
        req.success { item in
            XCTAssertEqual(item.a, "A")
            XCTAssertEqual(item.b, 123)
            fetchExpectation.fulfill()
        }
        req.failure { error in
            XCTFail(error.localizedDescription)
            fetchExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}
