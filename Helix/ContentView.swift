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
                    .foregroundColor(AppColors.bodyPrimaryText)
                Button("Sign Out") {
                    authManager.signOut()
                }
                .foregroundColor(AppColors.primaryText)
                .background(AppColors.primary)
            } else {
                AuthenticationView()
            }
        }
        .background(AppColors.background)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}