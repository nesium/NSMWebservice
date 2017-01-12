//
//  NSError+Webservice.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 12/01/2017.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation

public extension NSError {
    
    var isNetworkError: Bool {
        return self.domain == NSURLErrorDomain as String
    }
    
    var shouldRetryUsingReachability: Bool {
        guard self.isNetworkError else {
            return false
        }
        
        switch self.code {
            case
                NSURLErrorCancelled,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDNSLookupFailed,
                NSURLErrorNotConnectedToInternet,
                NSURLErrorTimedOut:
                return true
            
            default:
                return false
        }
    }
}
