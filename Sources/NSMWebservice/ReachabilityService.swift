//
//  ReachabilityService.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 22.05.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import Foundation
import RxSwift

public protocol ReachabilityServiceType {
  func connection() -> Observable<Reachability.Connection>
}



public class ReachabilityService: ReachabilityServiceType {
  private class ConnectionObserver {
    let handler: (Reachability.Connection) -> ()

    init(handler: @escaping (Reachability.Connection) -> ()) {
      self.handler = handler
    }
  }

  private let reachability: Reachability
  private var observers = [ConnectionObserver]()

  public init() throws {
    guard let reachability = Reachability() else {
      throw NSError(domain: "NSMWebserviceErrorDomain", code: 0, userInfo: [
        NSLocalizedDescriptionKey: "Could not instanciate network reachability."
      ])
    }
    self.reachability = reachability
    self.reachability.whenReachable = { [unowned self] _ in
      self.connectionDidChange()
    }
    self.reachability.whenUnreachable = { [unowned self] _ in
      self.connectionDidChange()
    }
  }

  public func connection() -> Observable<Reachability.Connection> {
    return Observable.create { observer in
      var connectionObserver: ConnectionObserver?

      DispatchQueue.main.async {
        do {
          try connectionObserver = self.add() { observer.onNext($0) }
        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create {
        connectionObserver.map(self.remove)
      }
    }
  }

  private func add(
    handler: @escaping (Reachability.Connection) -> ()
  ) throws -> ConnectionObserver {
    do {
      try self.reachability.startNotifier()
      let observer = ConnectionObserver(handler: handler)
      self.observers.append(observer)
      return observer
    } catch {
      throw error
    }
  }

  private func remove(observer: ConnectionObserver) {
    guard let idx = self.observers.firstIndex(where: { $0 === observer }) else {
      return
    }

    self.observers.remove(at: idx)

    if self.observers.isEmpty {
      self.reachability.stopNotifier()
    }
  }

  private func connectionDidChange() {
    let currentObservers = self.observers
    currentObservers.forEach {
      $0.handler(self.reachability.connection)
    }
  }
}
