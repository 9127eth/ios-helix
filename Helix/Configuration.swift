//
//  Configuration.swift
//  Helix
//
//  Created by Richard Waithe on 10/10/24.
//

import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey:key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

enum ConfigurationKey {
    static let googleClientID = "GOOGLE_CLIENT_ID"
    static let googleReversedClientID = "GOOGLE_REVERSED_CLIENT_ID"
    static let googleAPIKey = "NEXT_PUBLIC_FIREBASE_API_KEY"
    static let googleGCMSenderID = "GOOGLE_GCM_SENDER_ID"
    static let googleAppID = "GOOGLE_APP_ID"
    static let firebaseDatabaseURL = "FIREBASE_DATABASE_URL"
}

