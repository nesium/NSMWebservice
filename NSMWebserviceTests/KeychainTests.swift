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
}
