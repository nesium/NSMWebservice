//
//  PrimitiveSequence+Webservice.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 23.02.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import RxSwift

extension PrimitiveSequence {
  public func mapToThrowingObservable<T>() -> Observable<Response<T>> where E == Result<T> {
    return self.asObservable().map { result in
      switch result {
        case let .success(response):
          return response
        case let .error(error):
          throw error
      }
    }
  }
}
