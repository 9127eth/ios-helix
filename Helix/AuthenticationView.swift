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
    @State private var isSignUp = true
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
            authButtonsView
            
            Divider()
                .background(AppColors.bodyPrimaryText)
                .padding(.vertical)
            
            emailAuthView
        }
        .padding()
        .background(AppColors.background)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text("Helix.")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(AppColors.bodyPrimaryText)
            
            Text("Helping people create memorable connections.")
                .font(.title2)
                .foregroundColor(AppColors.bodyPrimaryText)
            
            Text("Empower your personal brand with customizable digital business cards.")
                .font(.subheadline)
                .foregroundColor(AppColors.bodyPrimaryText)
                .multilineTextAlignment(.center)
            
            Text("Try it free, no credit card required.")
                .font(.caption)
                .foregroundColor(AppColors.bodyPrimaryText)
                .padding(.top, 5)
        }
    }
    
    private var authButtonsView: some View {
        VStack(spacing: 15) {
            Button(action: signInWithGoogle) {
                HStack {
                    Image(systemName: "g.circle.fill")
                    Text("Continue with Google")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .foregroundColor(AppColors.primaryText)
                .cornerRadius(25)
            }
            
            Button(action: signInWithApple) {
                HStack {
                    Image(systemName: "apple.logo")
                    Text("Continue with Apple")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .foregroundColor(AppColors.primaryText)
                .cornerRadius(25)
            }
        }
    }
    
    private var emailAuthView: some View {
        VStack {
            Picker("", selection: $isSignUp) {
                Text("Sign Up").tag(true)
                Text("Log In").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: handleEmailAuth) {
                Text(isSignUp ? "Sign Up" : "Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .foregroundColor(AppColors.primaryText)
                    .cornerRadius(25)
            }
            .padding(.top)
        }
    }
    
    private func handleEmailAuth() {
        if isSignUp {
            authManager.signUpWithEmail(email: email, password: password) { result in
                handleAuthResult(result)
            }
        } else {
            authManager.signInWithEmail(email: email, password: password) { result in
                handleAuthResult(result)
            }
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
    
    private func signInWithApple() {
        authManager.signInWithApple { result in
            handleAuthResult(result)
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
}