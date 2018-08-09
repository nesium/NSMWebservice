//
//  Session.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 29.08.15.
//  Copyright © 2015 nesiumdotcom. All rights reserved.
//

import Foundation
import os.log
import RxSwift

final public class Session: NSObject, WebserviceSession, URLSessionDelegate {
  public let baseURL: URL
  public let gzipRequests: Bool

  private var session: URLSession!
  private let certificates: [SecCertificate]?

  private let requestLogger: ((URLRequest) -> ())?
  private let responseLogger: ((URL?, Data?, URLResponse?, Error?) -> ())?

  // MARK: - Initialization -

  public init(
    baseURL: URL,
    gzipRequests: Bool = true,
    requestLogger: ((URLRequest) -> ())? = nil,
    responseLogger: ((URL?, Data?, URLResponse?, Error?) -> ())? = nil
  ) {
    self.baseURL = baseURL
    self.gzipRequests = gzipRequests
    self.session = URLSession(configuration: URLSessionConfiguration.default)
    self.certificates = nil
    self.requestLogger = requestLogger
    self.responseLogger = responseLogger

    super.init()
  }

  public init(
    baseURL: URL,
    gzipRequests: Bool = true,
    certificateURLs: [URL],
    requestLogger: ((URLRequest) -> ())? = nil,
    responseLogger: ((URL?, Data?, URLResponse?, Error?) -> ())? = nil
  ) throws {
    self.baseURL = baseURL
    self.gzipRequests = gzipRequests
    self.certificates = try certificateURLs.map { url in
      guard let certificate = try SecCertificateCreateWithData(
        nil, Data(contentsOf: url) as CFData
      ) else {
        throw NSError(
          domain: "SessionErrorDomain",
          code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Certificate at path '\(url)' could not be read."]
        )
      }
      return certificate
    }
    self.requestLogger = requestLogger
    self.responseLogger = responseLogger

    super.init()

    self.session = URLSession(
      configuration: URLSessionConfiguration.default,
      delegate: self,
      delegateQueue: nil
    )
  }

  // MARK: - WebserviceSession Protocol -

  public func request<I>(_ request: Request<I>) -> Single<ResponseResult<Void>> {
    return self.request(request) { _ in () }
  }

  public func request<I, O: Decodable & JSONValue>(
    _ type: O.Type,
    _ request: Request<I>) -> Single<ResponseResult<O>> {
    return self.request(request, parser: JSONFragmentResponseParser)
  }

  public func request<I, O: Decodable>(
    _ type: O.Type, _ request: Request<I>
  ) -> Single<ResponseResult<O>> {
    return self.request(request, parser: JSONResponseParser)
  }

  // MARK: - Private Methods -

  private func request<I, O>(
    _ request: Request<I>,
    parser: @escaping ResponseParser<O>) -> Single<ResponseResult<O>> {
    return Single<ResponseResult<O>>.create { [unowned self] observer in
      var task: URLSessionDataTask?

      DispatchQueue.global().async {
        let urlRequest: URLRequest
        do {
          urlRequest = try request.urlRequest(with: self.baseURL, gzip: self.gzipRequests)
        } catch {
          observer(.success(ResponseResult.error(error)))
          return
        }

        let url = urlRequest.url
        self.requestLogger?(urlRequest)

        task = self.session.dataTask(with: urlRequest) { (data, response, error) in
          if let error = error {
            observer(.success(ResponseResult.error(error)))
            return
          }

          self.responseLogger?(url, data, response, error)

          do {
            try observer(.success(ResponseResult(
              urlResponse: response,
              data: data,
              parser: parser
            )))
          } catch {
            observer(.success(ResponseResult.error(error)))
          }
        }
        task!.resume()
      }

      return Disposables.create { task?.cancel() }
    }
  }

  // MARK: - URLSessionDelegate Protocol -

  public func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    guard let certificates = self.certificates else {
      completionHandler(.performDefaultHandling, nil)
      return
    }

    guard
      let trust = challenge.protectionSpace.serverTrust,
      SecTrustGetCertificateCount(trust) > 0 else
    {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    SecTrustSetPolicies(
      trust,
      SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)
    )

    SecTrustSetAnchorCertificates(trust, certificates as CFArray)
    SecTrustSetAnchorCertificatesOnly(trust, true)

    var isValid = false
    var result = SecTrustResultType.invalid

    if SecTrustEvaluate(trust, &result) == errSecSuccess {
      isValid = result == .unspecified || result == .proceed
    }

    guard isValid else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    completionHandler(.useCredential, URLCredential(trust: trust))
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

internal func JSONResponseParser<T: Decodable>(_ data: Data?) throws -> T {
  return try WSJSONDecoder().decode(T.self, from: NonEmptyDataResponseParser(data))
}
