//
//  HelixApp.swift
//  Helix
//
//  Created by Richard Waithe on 10/8/24.
//

import SwiftUI
import FirebaseCore

@main
struct HelixApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
        }
    }
}
