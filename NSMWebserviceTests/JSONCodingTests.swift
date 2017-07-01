//
//  JSONCodingTests.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 21.04.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import XCTest
@testable import NSMWebservice

class JSONCodingTests: XCTestCase {

  func testStringCoding() {
    XCTAssertTrue(try testJSONValueCoding(name: "string", expectedValue: "Hello World"))
  }

  func testIntCoding() {
    XCTAssertTrue(try testJSONValueCoding(name: "int", expectedValue: Int(123456)))
  }

  // Disabled for the time being as the cast `let dict = obj as? [String : T]` in the decoder
  // method fails. Obj is actually a [String: NSNumber].
//  func testFloatCoding() {
//    XCTAssertTrue(try testJSONValueCoding(name: "float", expectedValue: Float(123.456)))
//  }

  func testDoubleCoding() {
    XCTAssertTrue(try testJSONValueCoding(name: "double", expectedValue: Double(123.4567891)))
  }

  func testBoolCoding() {
    XCTAssertTrue(try testJSONValueCoding(name: "bool_true", expectedValue: true))
    XCTAssertTrue(try testJSONValueCoding(name: "bool_false", expectedValue: false))
  }

  func testJSONValueArrayCoding() {
    let (dec, dict): (NSMWebservice.JSONDecoder, [String: [String]]) = try! decoder(for: "string_array")
    let obj: JSONValueConvertibleArray<String> = try! JSONValueConvertibleArray(decoder: dec)
    XCTAssertEqual(obj.value, ["Hello", "World"])
    XCTAssertEqual(obj.optionalValue!, ["Hello", "World"])

    let enc: NSMWebservice.JSONEncoder = JSONEncoder(className: "string_array")
    try! obj.encode(encoder: enc)
    XCTAssertEqual(dict["items"]!, (enc.jsonDictionary as! [String: [String]])["items"]!)
  }

  func testJSONConvertibleCoding() {
    let (dec, _): (NSMWebservice.JSONDecoder, [String: Any]) = try! decoder(for: "json_convertible")
    let obj: Company = try! Company(decoder: dec)
    XCTAssertEqual(obj, Company(name: "Apple", employees: [
      Employee(name: "Tim Cook", salary: 1300000),
      Employee(name: "Johny Ive", salary: 1200000),
      Employee(name: "Phil Schiller", salary: 1100000)
    ]))

    let enc: NSMWebservice.JSONEncoder = JSONEncoder(className: "string_array")
    try! obj.encode(encoder: enc)
    let result: [String: Any] = enc.jsonDictionary

    XCTAssertEqual(result.count, 2)
    XCTAssertEqual(result["name"] as? String, "Apple")

    let employees = result["employees"]! as! [[String : Any]]
    XCTAssertEqual(employees.count, 3)

    XCTAssertEqual(employees[0]["name"] as? String, "Tim Cook")
    XCTAssertEqual(employees[0]["salary"] as? Double, 1300000)
    XCTAssertEqual(employees[1]["name"] as? String, "Johny Ive")
    XCTAssertEqual(employees[1]["salary"] as? Double, 1200000)
    XCTAssertEqual(employees[2]["name"] as? String, "Phil Schiller")
    XCTAssertEqual(employees[2]["salary"] as? Double, 1100000)
  }

  func testValueTransformerCoding() {
    let (dec, dict): (NSMWebservice.JSONDecoder, [String: String]) = try! decoder(for: "value_transformer")
    do {
      let obj: OrdinalJSONConvertible = try OrdinalJSONConvertible(decoder: dec)
      XCTAssertEqual(obj.value, 101)
      XCTAssertEqual(obj.optionalValue, 101)

      let enc: NSMWebservice.JSONEncoder = JSONEncoder(className: "value_transformer")
      try obj.encode(encoder: enc)
      XCTAssertEqual(dict, (enc.jsonDictionary as! [String: String]))
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testURLCoding() {
    let (dec, dict): (NSMWebservice.JSONDecoder, [String: String]) = try! decoder(for: "url")
    let obj: URLJSONConvertible = try! URLJSONConvertible(decoder: dec)
    XCTAssertEqual(obj.value,
    	URL(string: "https://www.example.com/path?arg1=0&arg2=hello%20world")!)

    let enc: NSMWebservice.JSONEncoder = JSONEncoder(className: "url")
    try! obj.encode(encoder: enc)
    XCTAssertEqual(dict, (enc.jsonDictionary as! [String: String]))
  }

  func testDateCoding() {
    let (dec, dict): (NSMWebservice.JSONDecoder, [String: String]) = try! decoder(for: "date")
    let obj: DateJSONConvertible = try! DateJSONConvertible(decoder: dec)

    let components: DateComponents = DateComponents(
    	calendar: Calendar.current,
      timeZone: TimeZone(secondsFromGMT: 0),
      year: 2016,
      month: 12,
      day: 24,
      hour: 20,
      minute: 15,
      second: 30)
    let date: Date = Calendar.current.date(from: components)!

    XCTAssertEqual(obj.value.timeIntervalSince1970, date.timeIntervalSince1970)

    let enc: NSMWebservice.JSONEncoder = JSONEncoder(className: "date")
    try! obj.encode(encoder: enc)
    XCTAssertEqual(dict, (enc.jsonDictionary as! [String: String]))
  }
}



fileprivate struct JSONValueConvertible<T: JSONValue>: JSONConvertible {
  let value: T
  let optionalValue: T?

  init(decoder: NSMWebservice.JSONDecoder) throws {
    self.value = try decoder.decode("item")
    self.optionalValue = try decoder.decode("item")

    do {
      let missingValue: T = try decoder.decode("missing_item")
      _ = missingValue // silence unused result warning
      XCTFail("Method should have thrown")
    } catch let e as ParseError {
      switch e {
        case let .missingField(fieldName, _):
          XCTAssertEqual(fieldName, "missing_item")
        default:
          XCTFail("Unexpected error")
      }
    } catch {
      XCTFail("Unexpected error")
    }
  }

  func encode(encoder: NSMWebservice.JSONEncoder) throws {
    try encoder.encode("item", self.value)
  }
}


fileprivate struct JSONValueConvertibleArray<T: JSONValue>: JSONConvertible {
  let value: [T]
  let optionalValue: [T]?

  init(decoder: NSMWebservice.JSONDecoder) throws {
    self.value = try decoder.decode("items")
    self.optionalValue = try decoder.decode("items")

    do {
      let missingValue: [T] = try decoder.decode("missing_item")
      _ = missingValue // silence unused result warning
      XCTFail("Method should have thrown")
    } catch let e as ParseError {
      switch e {
        case let .missingField(fieldName, _):
          XCTAssertEqual(fieldName, "missing_item")
        default:
          XCTFail("Unexpected error")
      }
    } catch {
      XCTFail("Unexpected error")
    }
  }

  func encode(encoder: NSMWebservice.JSONEncoder) throws {
    try encoder.encode("items", self.value)
  }
}


fileprivate struct Company: JSONConvertible, Equatable {
  let name: String
  let employees: [Employee]

  init(name: String, employees: [Employee]) {
    self.name = name
    self.employees = employees
  }

  init(decoder: NSMWebservice.JSONDecoder) throws {
    self.name = try decoder.decode("name")
    self.employees = try decoder.decode("employees")
  }

  func encode(encoder: NSMWebservice.JSONEncoder) throws {
    try encoder.encode("name", self.name)
    try encoder.encode("employees", self.employees)
  }

  static func ==(lhs: Company, rhs: Company) -> Bool {
    return lhs.name == rhs.name && lhs.employees == rhs.employees
  }
}


fileprivate struct Employee: JSONConvertible, Equatable {
  let name: String
  let salary: Double

  init(name: String, salary: Double) {
    self.name = name
    self.salary = salary
  }

  init(decoder: NSMWebservice.JSONDecoder) throws {
    self.name = try decoder.decode("name")
    self.salary = try decoder.decode("salary")
  }

  func encode(encoder: NSMWebservice.JSONEncoder) throws {
    try encoder.encode("name", self.name)
    try encoder.encode("salary", self.salary)
  }

  static func ==(lhs: Employee, rhs: Employee) -> Bool {
    return lhs.name == rhs.name && lhs.salary == rhs.salary
  }
}


fileprivate struct URLJSONConvertible: JSONConvertible {
  let value: URL

  init(decoder: NSMWebservice.JSONDecoder) throws {
    self.value = try decoder.decode("item")
  }

  func encode(encoder: NSMWebservice.JSONEncoder) throws {
    try encoder.encode("item", self.value)
  }
}


fileprivate struct DateJSONConvertible: JSONConvertible {
  let value: Date

  init(decoder: NSMWebservice.JSONDecoder) throws {
    self.value = try decoder.decode("item")
  }

  func encode(encoder: NSMWebservice.JSONEncoder) throws {
    try encoder.encode("item", self.value)
  }
}

fileprivate struct OrdinalJSONConvertible: JSONConvertible {
  let value: Int
  let optionalValue: Int?

  init(decoder: NSMWebservice.JSONDecoder) throws {
    self.value = try decoder.decode("item", transformer: OrdinalNumberTransformer())
    self.optionalValue = try decoder.decode("item", transformer: OrdinalNumberTransformer())
  }

  func encode(encoder: NSMWebservice.JSONEncoder) throws {
    try encoder.encode("item", self.value, transformer: OrdinalNumberTransformer())
  }
}


fileprivate struct TestError: Error {
  public let localizedDescription: String

  init(_ msg: String) {
    self.localizedDescription = msg
  }
}

fileprivate struct OrdinalNumberTransformer: NSMWebservice.ValueTransformer {
  typealias InType = String
  typealias OutType = Int

  func transformedValue(_ value: String) throws -> Int {
    let formatter: NumberFormatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return try formatter.objectValueForString(value)
  }

  func reverseTransformedValue(_ value: Int) -> String {
    let formatter: NumberFormatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(from: NSNumber(value: value))!
  }
}


fileprivate func testJSONValueCoding<T>(name: String, expectedValue: T) throws -> Bool
	where T: JSONValue & Equatable {
  let (dec, dict): (NSMWebservice.JSONDecoder, [String: T]) = try decoder(for: name)
  let obj: JSONValueConvertible<T> = try JSONValueConvertible(decoder: dec)
  XCTAssertEqual(obj.value, expectedValue)
  XCTAssertEqual(obj.optionalValue, expectedValue)

  let enc: NSMWebservice.JSONEncoder = JSONEncoder(className: name)
  try obj.encode(encoder: enc)
  XCTAssertEqual(dict, enc.jsonDictionary as! [String: T])

  return true
}


fileprivate func decoder<T>(for name: String) throws -> (NSMWebservice.JSONDecoder, [String: T]) {
  guard let path: String =
  	Bundle(for: JSONCodingTests.self).path(forResource: name, ofType: "json") else {
    throw TestError("Could not find JSON file with name \(name)")
  }

  guard let stream: InputStream = InputStream(fileAtPath: path) else {
    throw TestError("Could not read from JSON file at path '\(path)'")
  }
  stream.open()

  let obj: Any = try JSONSerialization.jsonObject(with: stream, options: [])
  guard let dict = obj as? [String : T] else {
    throw TestError("Invalid root type in JSON file at path '\(path)'")
  }

  let deserializer: JSONDeserializer = JSONDeserializer(deserializationContext: nil)
  let decoder: NSMWebservice.JSONDecoder = JSONDecoder(dict, className: name, deserializer: deserializer,
  	deserializationContext: nil)

  return (decoder, dict)
}
