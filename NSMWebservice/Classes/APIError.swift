//
//  APIError.swift
//  Bookshelf
//
//  Created by Marc Bauer on 01.01.16.
//  Copyright © 2016 nesiumdotcom. All rights reserved.
//

import Foundation

class APIError : NSError {

	init(dict: [String: Any]) {
        let message = dict["message"] as? String ?? "An unknown error occured"
        
        super.init(
        	domain: "APIErrorDomain",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: message
            ])
    }

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
