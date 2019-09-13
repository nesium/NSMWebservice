//
//  KeychainTests.swift
//  NSMWebserviceTests
//
//  Created by Marc Bauer on 01.07.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import NSMWebservice
import XCTest

// To run this tests, as of Xcode 9b2, a test host is required.
// For more information see: https://forums.developer.apple.com/thread/60617

class KeychainTests: XCTestCase {
  func testPut() {
    let savedItem = Keychain.Item(
      account: "hello@world.com",
      password: "secret",
      token: "token",
      refreshToken: "refreshToken"
    )
    let url: URL = URL(string: "http://www.example.com")!
    
    do {
      try Keychain.put(item: savedItem, for: url)
      let fetchedItem = try Keychain.fetchItem(for: url)
      XCTAssertEqual(fetchedItem, savedItem)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testPutGenericItem() {
    let item1 = Keychain.GenericItem(
      account: "account1",
      username: "John Doe",
      email: "john@email.com",
      password: "secret"
    )
    let item2 = Keychain.GenericItem(
      account: "account2",
      username: "Mike Smith",
      email: "mike@email.com",
      password: "supersecret"
    )

    do {
      try Keychain.put(item: item1, for: "myservice", account: item1.account)
      try Keychain.put(item: item2, for: "myservice", account: item2.account)
      let fetchedItem1 = try Keychain.fetchItem(for: "myservice", account: item1.account)
      let fetchedItem2 = try Keychain.fetchItem(for: "myservice", account: item2.account)
      XCTAssertEqual(fetchedItem1, item1)
      XCTAssertEqual(fetchedItem2, item2)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testUpdate() {
    let savedItem = Keychain.Item(
      account: "hello@world.com",
      password: "secret",
      token: "token",
      refreshToken: "refreshToken"
    )
    let updatedItem = Keychain.Item(
      account: "email@me.com",
      password: "supersecret",
      token: "new-token",
      refreshToken: nil
    )

    let url: URL = URL(string: "http://www.example.com")!

    do {
      try Keychain.put(item: savedItem, for: url)
      try Keychain.put(item: updatedItem, for: url)
      let fetchedItem = try Keychain.fetchItem(for: url)
      XCTAssertEqual(fetchedItem, updatedItem)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testUpdateGenericItem() {
    let item1 = Keychain.GenericItem(
      account: "account1",
      username: "John Doe",
      email: "john@email.com",
      password: "secret"
    )
    let item2 = Keychain.GenericItem(
      account: "account2",
      username: "Mike Smith",
      email: "mike@email.com",
      password: "supersecret"
    )
    let updatedItem2 = Keychain.GenericItem(
      account: "account2",
      username: "Mike Smithers",
      email: "mikes@email.com",
      password: "supersecrets"
    )

    do {
      try Keychain.put(item: item1, for: "myservice", account: item1.account)
      try Keychain.put(item: item2, for: "myservice", account: item2.account)
      try Keychain.put(item: updatedItem2, for: "myservice", account: item2.account)
      let fetchedItem1 = try Keychain.fetchItem(for: "myservice", account: item1.account)
      let fetchedItem2 = try Keychain.fetchItem(for: "myservice", account: item2.account)
      XCTAssertEqual(fetchedItem1, item1)
      XCTAssertEqual(fetchedItem2, updatedItem2)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testDelete() {
    let savedItem = Keychain.Item(
      account: "hello@world.com",
      password: "secret",
      token: "token",
      refreshToken: "refreshToken"
    )
    let url: URL = URL(string: "http://www.example.com")!

    do {
      try Keychain.put(item: savedItem, for: url)
      try Keychain.deleteItem(for: url)
      let fetchedItem = try Keychain.fetchItem(for: url)
      XCTAssertNil(fetchedItem)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testDeleteGenericItem() {
    let item1 = Keychain.GenericItem(
      account: "account1",
      username: "John Doe",
      email: "john@email.com",
      password: "secret"
    )
    let item2 = Keychain.GenericItem(
      account: "account2",
      username: "Mike Smith",
      email: "mike@email.com",
      password: "supersecret"
    )

    do {
      try Keychain.put(item: item1, for: "myservice", account: item1.account)
      try Keychain.put(item: item2, for: "myservice", account: item2.account)
      try Keychain.deleteItem(for: "myservice", account: item1.account)
      let fetchedItem1 = try Keychain.fetchItem(for: "myservice", account: item1.account)
      let fetchedItem2 = try Keychain.fetchItem(for: "myservice", account: item2.account)
      XCTAssertNil(fetchedItem1)
      XCTAssertEqual(fetchedItem2, item2)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }
}
