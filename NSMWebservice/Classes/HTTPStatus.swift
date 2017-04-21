//
//  HTTPStatus.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 02/01/2017.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation

public enum HTTPStatus: Int, CustomStringConvertible {
  case Continue = 100
  case SwitchingProtocols = 101
  case Processing = 102
  case Ok = 200
  case Created = 201
  case Accepted = 202
  case NonAuthoritativeInformation = 203
  case NoContent = 204
  case ResetContent = 205
  case PartialContent = 206
  case MultiStatus = 207
  case AlreadyReported = 208
  case IMUsed = 209
  case MultipleChoice = 300
  case MovedPermanently = 301
  case Found = 302
  case SeeOther = 303
  case NotModified = 304
  case UseProxy = 305
  case SwitchProxy = 306
  case TemporaryRedirect = 307
  case PermanentRedirect = 308
  case BadRequest = 400
  case Unauthorized = 401
  case PaymentRequired = 402
  case Forbidden = 403
  case NotFound = 404
  case MethodNotAllowed = 405
  case NotAcceptable = 406
  case ProxyAuthenticationRequired = 407
  case RequestTimeOut = 408
  case Conflict = 409
  case Gone = 410
  case LengthRequired = 411
  case PreconditionFailed = 412
  case PayloadTooLarge = 413
  case URITooLong = 414
  case UnsupportedMediaType = 415
  case RangeNotSatisfiable = 416
  case ExpectationFailed = 417
  case ImATeapot = 418
  case MisdirectedRequest = 421
  case UnprocessableEntity = 422
  case Locked = 423
  case FailedDependency = 424
  case UpgradeRequired = 426
  case PreconditionRequired = 428
  case TooManyRequests = 429
  case RequestHeaderFieldsTooLarge = 431
  case UnavailableForLegalReasons = 451
  case InternalServerError = 500
  case NotImplemented = 501
  case BadGateway = 502
  case ServiceUnavailable = 503
  case GatewayTimeOut = 504
  case HTTPVersionNotSupported = 505
  case VariantAlsoNegotiates = 506
  case InsufficientStorage = 507
  case LoopDetected = 508
  case NotExtended = 510
  case NetworkAuthenticationRequired = 511
  case UnknownError = 10000

  var isSuccess: Bool {
    return self.rawValue < 300
  }

  var isError: Bool {
    return self.rawValue >= 300
  }

  public var description: String {
    var msg: String

    switch self {
      case .Continue:
        msg = "Continue"
      case .SwitchingProtocols:
        msg = "Switching Protocols"
      case .Processing:
        msg = "Processing"
      case .Ok:
        msg = "Ok"
      case .Created:
        msg = "Created"
      case .Accepted:
        msg = "Accepted"
      case .NonAuthoritativeInformation:
        msg = "Non Authoritive Information"
      case .NoContent:
        msg = "No Content"
      case .ResetContent:
        msg = "Reset Content"
      case .PartialContent:
        msg = "Partial Content"
      case .MultiStatus:
        msg = "Multi Status"
      case .AlreadyReported:
        msg = "Already Reported"
      case .IMUsed:
        msg = "IM Used"
      case .MultipleChoice:
        msg = "Multiple Choice"
      case .MovedPermanently:
        msg = "Moved Permanently"
      case .Found:
        msg = "Found"
      case .SeeOther:
        msg = "See Other"
      case .NotModified:
        msg = "Not Modified"
      case .UseProxy:
        msg = "Use Proxy"
      case .SwitchProxy:
        msg = "Switch Proxy"
      case .TemporaryRedirect:
        msg = "Temporary Redirect"
      case .PermanentRedirect:
        msg = "Permanent Redirect"
      case .BadRequest:
        msg = "Bad Request"
      case .Unauthorized:
        msg = "Unauthorized"
      case .PaymentRequired:
        msg = "PaymentRequired"
      case .Forbidden:
        msg = "Forbidden"
      case .NotFound:
        msg = "Not Found"
      case .MethodNotAllowed:
        msg = "Method Not Allowed"
      case .NotAcceptable:
        msg = "Not Acceptable"
      case .ProxyAuthenticationRequired:
        msg = "Proxy Authentication Required"
      case .RequestTimeOut:
        msg = "Request Time Out"
      case .Conflict:
        msg = "Conflict"
      case .Gone:
        msg = "Gone"
      case .LengthRequired:
        msg = "Length Required"
      case .PreconditionFailed:
        msg = "Precondition Failed"
      case .PayloadTooLarge:
        msg = "Payload Too Large"
      case .URITooLong:
        msg = "URI Too Long"
      case .UnsupportedMediaType:
        msg = "Unsupported Media Type"
      case .RangeNotSatisfiable:
        msg = "Range Not Satisfiable"
      case .ExpectationFailed:
        msg = "Expectation Failed"
      case .ImATeapot:
        msg = "I'm A Teapot"
      case .MisdirectedRequest:
        msg = "Misdirected Request"
      case .UnprocessableEntity:
        msg = "Unprocessable Entity"
      case .Locked:
        msg = "Locked"
      case .FailedDependency:
        msg = "Failed Dependency"
      case .UpgradeRequired:
        msg = "Upgrade Required"
      case .PreconditionRequired:
        msg = "Precondition Required"
      case .TooManyRequests:
        msg = "Too Many Requests"
      case .RequestHeaderFieldsTooLarge:
        msg = "Request Header Fields Too Large"
      case .UnavailableForLegalReasons:
        msg = "Unavailable For Legal Reasons"
      case .InternalServerError:
        msg = "Internal Server Error"
      case .NotImplemented:
        msg = "Not Implemented"
      case .BadGateway:
        msg = "Bad Gateway"
      case .ServiceUnavailable:
        msg = "Service Unavailable"
      case .GatewayTimeOut:
        msg = "Gateway Time Out"
      case .HTTPVersionNotSupported:
        msg = "HTTP Version Not Supported"
      case .VariantAlsoNegotiates:
        msg = "Variant Also Negotiates"
      case .InsufficientStorage:
        msg = "Insufficient Storage"
      case .LoopDetected:
        msg = "Loop Detected"
      case .NotExtended:
        msg = "Not Extended"
      case .NetworkAuthenticationRequired:
        msg = "Network Authentication Required"
      case .UnknownError:
        msg = "Unknown Error"
    }

    return "\(self.rawValue) (\(msg))"
  }
}
