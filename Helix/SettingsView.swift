//
//  SettingsView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    authManager.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
