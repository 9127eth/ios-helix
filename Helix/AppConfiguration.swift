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
        do {
            let googleClientID: String = try Configuration.value(for: ConfigurationKey.googleClientID)
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: googleClientID)
        } catch {
            print("Configuration error: \(error)")
        }
    }
    
    static func setupFirebase() {
        do {
            let apiKey: String = try Configuration.value(for: ConfigurationKey.googleAPIKey)
            print("Debug: Firebase API Key - \(apiKey)")
            if apiKey.count != 39 || !apiKey.hasPrefix("A") {
                print("Invalid API Key format. Please check your configuration.")
                return
            }
            FirebaseApp.configure()
        } catch {
            print("Configuration error: \(error)")
        }
    }
    
    static func setupAll() {
        setupFirebase()
        setupGoogleSignIn()
    }
}

