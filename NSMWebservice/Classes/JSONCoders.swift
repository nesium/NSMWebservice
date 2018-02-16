//
//  JSONCoders.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 16.02.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import Foundation

public class WSJSONEncoder: JSONEncoder {
  public override init() {
    super.init()
    self.dateEncodingStrategy = .formatted(ISO8601DateTimeTransformer.formatter)
  }
}

public class WSJSONDecoder: JSONDecoder {
  public override init() {
    super.init()
    self.dateDecodingStrategy = .formatted(ISO8601DateTimeTransformer.formatter)
  }
}
