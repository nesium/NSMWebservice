//
//  ActivityIndicator+NSMWebservice.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 21.04.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

#if os(iOS)
import UIKit
#endif

extension ActivityIndicator {
  public static var shared: ActivityIndicator = ActivityIndicator()

  #if os(iOS)
  public func driveNetworkActivityIndicator() -> Disposable {
    return self.asDriver().drive(UIApplication.shared.rx.isNetworkActivityIndicatorVisible)
  }
  #endif
}
