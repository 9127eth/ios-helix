//
//  ContentView.swift
//  Helix
//
//  Created by Richard Waithe on 10/8/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                Text("Welcome, \(authManager.user?.email ?? "User")!")
                Button("Sign Out") {
                    authManager.signOut()
                }
            } else {
                AuthenticationView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}