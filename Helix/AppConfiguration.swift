//
//  AppConfiguration.swift
//  Helix
//
//  Created by Richard Waithe on 10/10/24.
//

import Foundation
import GoogleSignIn
import Firebase

struct AppConfiguration {
    static func setupGoogleSignIn() {
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let clientID = plist["CLIENT_ID"] as? String else {
            print("Error: Failed to get Google Client ID from GoogleService-Info.plist")
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
    
    static func setupAll() {
        setupGoogleSignIn()
    }
}

