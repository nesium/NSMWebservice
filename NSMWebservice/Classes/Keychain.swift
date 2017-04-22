//
//  Keychain.swift
//  NSMWebservice
//
//  Created by Marc Bauer on 02.01.16.
//  Copyright © 2016 nesiumdotcom. All rights reserved.
//

import Foundation

public class Keychain {
    
    public static func saveAuthToken(_ apiURL: URL, eMail: String, authToken: String) {
        let savedToken = retrieveAuthToken(apiURL, eMail: authToken)
        
        if savedToken == authToken {
            return
        }
        
        var result: OSStatus
        
        if savedToken != nil {
            let query: [NSString: AnyObject] = [
                kSecClass: kSecClassInternetPassword,
                kSecAttrServer: apiURL.absoluteString as AnyObject,
                kSecAttrAccount: eMail as AnyObject
            ]
            let update: [NSString: AnyObject] = [
                kSecValueData: authToken.data(using: String.Encoding.utf8)! as AnyObject
            ]
            result = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        } else {
            let attributes: [NSString: AnyObject] = [
                kSecClass: kSecClassInternetPassword,
                kSecAttrServer: apiURL.absoluteString as AnyObject,
                kSecAttrAccount: eMail as AnyObject,
                kSecValueData: authToken.data(using: String.Encoding.utf8)! as AnyObject
            ]
            result = SecItemAdd(attributes as CFDictionary, nil)
        }
        
        if result != noErr {
            print("Could not create keychain entry (\(result))")
        }
    }
    
    public static func retrieveAuthToken(_ apiURL: URL, eMail: String) -> String? {
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: apiURL.absoluteString as AnyObject,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true as AnyObject,
            kSecAttrAccount: eMail as AnyObject
        ]
    
        var data: AnyObject?
        let result = SecItemCopyMatching(query as CFDictionary, &data)
        
        if result == errSecSuccess {
            return String(data: data as! Data, encoding: String.Encoding.utf8)!
        }
        
        return nil
    }
    
    public static func deleteAuthToken(_ apiURL: URL, eMail: String) {
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: apiURL.absoluteString as AnyObject,
            kSecAttrAccount: eMail as AnyObject
        ]
        
        let result = SecItemDelete(query as CFDictionary)
        
        if result != errSecSuccess {
            print("Could not delete keychain entry")
        }
    }
}
