//
//  Session.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 29.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation
import RxSwift

final public class Session: WebserviceSession {
  public let baseURL: URL
  public let gzipRequests: Bool

  private let session: URLSession

  public init(baseURL: URL, gzipRequests: Bool = true) {
    self.baseURL = baseURL
    self.gzipRequests = gzipRequests
    self.session = URLSession(configuration: URLSessionConfiguration.default)
  }

  public func request<I>(_ request: Request<I>) -> Single<Result<Void>> {
    return self.request(request) { _ in () }
  }

  public func request<I, O: Decodable & JSONValue>(
    _ type: O.Type,
    _ request: Request<I>) -> Single<Result<O>> {
    return self.request(request, parser: JSONFragmentResponseParser)
  }

  public func request<I, O: Decodable>(_ type: O.Type, _ request: Request<I>) -> Single<Result<O>> {
    return self.request(request, parser: JSONResponseParser)
  }

  private func request<I, O>(
    _ request: Request<I>,
    parser: @escaping ResponseParser<O>) -> Single<Result<O>> {
    return Single<Result<O>>.create { [unowned self] observer in
      var task: URLSessionDataTask?

      DispatchQueue.global().async {
        let urlRequest: URLRequest
        do {
          urlRequest = try request.urlRequest(with: self.baseURL, gzip: self.gzipRequests)
        } catch {
          observer(.success(Result.error(error)))
          return
        }

        task = self.session.dataTask(with: urlRequest) { (data, response, error) in
          if let error = error {
            observer(.success(Result.error(error)))
            return
          }

          do {
            try observer(.success(Result(
              urlResponse: response,
              data: data,
              parser: parser
            )))
          } catch {
            observer(.success(Result.error(error)))
          }
        }
        task!.resume()
      }

      return Disposables.create { task?.cancel() }
    }
  }
}

fileprivate func NonEmptyDataResponseParser(_ data: Data?) throws -> Data {
  guard let data = data else {
    throw ResponseError.emptyResponse
  }
  return data
}

fileprivate func JSONFragmentResponseParser<T>(_ data: Data?) throws -> T {
  guard let decodedData =
    try JSONSerialization.jsonObject(
      with: NonEmptyDataResponseParser(data),
      options: .allowFragments) as? T else {
    throw ResponseError.unexpectedType
  }
  return decodedData
}

fileprivate func JSONResponseParser<T: Decodable>(_ data: Data?) throws -> T {
  return try WSJSONDecoder().decode(T.self, from: NonEmptyDataResponseParser(data))
}
