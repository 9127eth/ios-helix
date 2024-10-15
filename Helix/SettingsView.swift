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

    var body: some View {
        NavigationView {
            List {
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
        authManager.deleteAccount { result in
            switch result {
            case .success:
                print("Account deleted successfully")
                DispatchQueue.main.async {
                    self.isAuthenticated = false // This will trigger navigation back to the auth screen
                }
            case .failure(let error):
                print("Failed to delete account: \(error.localizedDescription)")
                // Handle error (e.g., show an error alert)
            }
        }
    }
}
