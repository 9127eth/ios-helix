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
    @State private var showEmailAuth = false
    @State private var isLogin = false
    @State private var username = ""
    @State private var agreeToTerms = false
    
    var body: some View {
        ZStack {
            Color(AppColors.background)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                headerView
                
                authButtonsView
                
                if showEmailAuth {
                    emailAuthView
                }
            }
            .padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .dismissKeyboardOnTap()  // Move this to the outermost view
        .contentShape(Rectangle())  // Add this line
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            Image("helix_logo")
                .resizable()
                .scaledToFit()
                .frame(height: 100)  // Adjust this value to fit your logo size
                .padding(.bottom, 15)  // Added padding below the logo
            
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
                AuthButtonView(image: "google_logo", text: "Continue with Google")
            }
            
            Button(action: signInWithApple) {
                AuthButtonView(image: "apple.logo", text: "Continue with Apple", isSystemImage: true)
            }
            
            Button(action: { showEmailAuth = true }) {
                AuthButtonView(image: "envelope", text: "Continue with Email", isSystemImage: true)
            }
        }
    }
    
    private var orSeparator: some View {
        HStack {
            VStack { Divider().background(AppColors.bodyPrimaryText) }
            Text("or")
                .foregroundColor(AppColors.bodyPrimaryText)
                .font(.footnote)
            VStack { Divider().background(AppColors.bodyPrimaryText) }
        }
        .padding(.vertical)
    }
    
    private var emailAuthView: some View {
        VStack(spacing: 15) {
            Text(isLogin ? "Welcome back!" : "Create an Account")
                .font(.headline)
                .foregroundColor(AppColors.bodyPrimaryText)
                .padding(.bottom, 10)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !isLogin {
                Toggle(isOn: $agreeToTerms) {
                    Text("I agree to the Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(AppColors.bodyPrimaryText)
                }
            }
            
            Button(action: handleEmailAuth) {
                Text(isLogin ? "Log In" : "Sign Up")
                    .frame(width: 160, height: 40)
                    .background(isLogin || agreeToTerms ? AppColors.buttonBackground : Color.gray.opacity(0.3))
                    .foregroundColor(isLogin || agreeToTerms ? AppColors.buttonText : Color.gray)
                    .cornerRadius(20)
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(!isLogin && !agreeToTerms)
            .padding(.top, 10)
            
            if isLogin {
                Button(action: { isLogin = false }) {
                    Text("Don't have an account? Sign up")
                        .font(.footnote)
                        .foregroundColor(AppColors.bodyPrimaryText)
                }
                .padding(.top, 5)
                
                Button(action: handleForgotPassword) {
                    Text("Forgot password?")
                        .font(.footnote)
                        .foregroundColor(AppColors.bodyPrimaryText)
                }
                .padding(.top, 5)
            } else {
                Button(action: { isLogin = true }) {
                    Text("Already have an account? Log in")
                        .font(.footnote)
                        .foregroundColor(AppColors.bodyPrimaryText)
                }
                .padding(.top, 5)
            }
        }
        .padding()
    }
    
    private func handleEmailAuth() {
        print("handleEmailAuth called")
        if isLogin {
            print("Attempting to sign in with email: \(email)")
            authManager.signInWithEmail(email: email, password: password) { result in
                handleAuthResult(result)
            }
        } else {
            print("Attempting to sign up with email: \(email)")
            Task {
                do {
                    let user = try await authManager.signUpWithEmail(email: email, password: password)
                    handleAuthResult(.success(user))
                } catch {
                    handleAuthResult(.failure(error))
                }
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

        Task {
            do {
                let user = try await authManager.signInWithGoogle(presenting: rootViewController)
                handleAuthResult(.success(user))
            } catch {
                handleAuthResult(.failure(error))
            }
        }
    }
    
    private func signInWithApple() {
        Task {
            do {
                let user = try await authManager.signInWithApple()
                handleAuthResult(.success(user))
            } catch {
                handleAuthResult(.failure(error))
            }
        }
    }
    
    private func handleAuthResult(_ result: Result<FirebaseAuth.User, Error>) {
        switch result {
        case .success(let user):
            print("Authentication successful for user: \(user.uid)")
            DispatchQueue.main.async {
                authManager.isAuthenticated = true
            }
        case .failure(let error):
            print("Authentication failed: \(error.localizedDescription)")
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func handleForgotPassword() {
        if email.isEmpty {
            alertMessage = "Please enter your email address."
            showingAlert = true
        } else {
            authManager.resetPassword(email: email) { result in
                switch result {
                case .success:
                    alertMessage = "Password reset email sent. Please check your inbox."
                    showingAlert = true
                case .failure(let error):
                    alertMessage = "Failed to send password reset email: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}
extension AuthenticationManager {
    static func mock() -> AuthenticationManager {
        let manager = AuthenticationManager()
        // Set up any necessary mock data here
        return manager
    }
}
