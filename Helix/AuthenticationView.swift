//
//  AuthenticationView.swift
//  Helix
//
//  Created by Richard Waithe on 10/9/24.
//

import SwiftUI
import Firebase

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign In") {
                authManager.signInWithEmail(email: email, password: password) { result in
                    switch result {
                    case .success:
                        print("Signed in successfully")
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                }
            }
            
            Button("Sign Up") {
                authManager.signUpWithEmail(email: email, password: password) { result in
                    switch result {
                    case .success:
                        print("Signed up successfully")
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                }
            }
            
            Button("Sign In with Google") {
                signInWithGoogle()
            }
            
            Button("Sign In with Apple") {
                authManager.signInWithApple { result in
                    switch result {
                    case .success:
                        print("Signed in with Apple successfully")
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                }
            }
        }
        .padding()
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Failed to get root view controller")
            return
        }

        authManager.signInWithGoogle(presenting: rootViewController) { result in
            switch result {
            case .success(let user):
                print("Signed in successfully: \(user.uid)")
            case .failure(let error):
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}