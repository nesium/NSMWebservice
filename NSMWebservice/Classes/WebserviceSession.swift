//
//  WebserviceSession.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 09/01/2017.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation
import RxSwift

public protocol WebserviceSession {
  func request<I>(_ request: Request<I>) -> Single<Result<Empty>>
  func request<I, O>(_ type: O.Type, _ request: Request<I>) -> Single<Result<O>>
}
