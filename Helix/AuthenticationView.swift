//
//  AuthenticationView.swift
//  Helix
//
//  Created by Richard Waithe on 10/9/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

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
                .foregroundColor(AppColors.bodyPrimaryText)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(AppColors.bodyPrimaryText)
            
            Button("Sign In") {
                authManager.signInWithEmail(email: email, password: password) { result in
                    handleAuthResult(result)
                }
            }
            .foregroundColor(AppColors.primaryText)
            .background(AppColors.primary)
            
            Button("Sign Up") {
                authManager.signUpWithEmail(email: email, password: password) { result in
                    handleAuthResult(result)
                }
            }
            .foregroundColor(AppColors.primaryText)
            .background(AppColors.primary)
            
            Button("Sign In with Google") {
                signInWithGoogle()
            }
            .foregroundColor(AppColors.primaryText)
            .background(AppColors.primary)
            
            Button("Sign In with Apple") {
                authManager.signInWithApple { result in
                    handleAuthResult(result)
                }
            }
            .foregroundColor(AppColors.primaryText)
            .background(AppColors.primary)
        }
        .padding()
        .background(AppColors.background)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func handleAuthResult(_ result: Result<FirebaseAuth.User, Error>) {
        switch result {
        case .success(let user):
            print("Authentication successful for user: \(user.uid)")
        case .failure(let error):
            alertMessage = error.localizedDescription
            showingAlert = true
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
            handleAuthResult(result)
        }
    }
}