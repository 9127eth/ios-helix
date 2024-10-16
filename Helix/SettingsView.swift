//
//  SettingsView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI
import Firebase

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showDeleteConfirmation = false
    @Binding var isAuthenticated: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }

                Section(header: Text("Account")) {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to delete your account? This action is irreversible."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteAccount()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func deleteAccount() {
        // Implement account deletion logic here
    }
}
