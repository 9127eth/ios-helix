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
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(AppColors.background)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView(geometry: geometry)
                        
                        // Authentication buttons
                        authButtonsView
                        
                        // Show email authentication view if needed
                        if showEmailAuth {
                            emailAuthView
                        }
                        
                        Spacer(minLength: 10)
                        
                        // Terms and conditions text
                        Text("By continuing, you agree to our [Terms of Service](https://www.helixcard.app/terms-of-service) and [Privacy Policy](https://www.helixcard.app/privacy-policy)")
                            .font(.caption)
                            .foregroundColor(AppColors.bodyPrimaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                    }
                    .padding(.horizontal)
                    .padding(.top, geometry.safeAreaInsets.top + 20)
                    .background(GeometryReader { proxy -> Color in
                        DispatchQueue.main.async {
                            scrollOffset = -proxy.frame(in: .named("scroll")).origin.y
                        }
                        return Color.clear
                    })
                }
                .coordinateSpace(name: "scroll")
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .dismissKeyboardOnTap()
        .contentShape(Rectangle())
    }
    
    private func headerView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Image("helix_logo")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .padding(.bottom, 15)
                .opacity(opacity(for: 0, geometry: geometry))
            
            Text("Helping people create memorable connections.")
                .font(.title2)
                .foregroundColor(AppColors.bodyPrimaryText)
                .opacity(opacity(for: 120, geometry: geometry))
            
            Text("Empower your personal brand with customizable digital business cards.")
                .font(.subheadline)
                .foregroundColor(AppColors.bodyPrimaryText)
                .multilineTextAlignment(.center)
                .opacity(opacity(for: 170, geometry: geometry))
            
            Text("Try it free, no credit card required.")
                .font(.caption)
                .foregroundColor(AppColors.bodyPrimaryText)
                .padding(.top, 5)
                .opacity(opacity(for: 220, geometry: geometry))
        }
    }
    
    private func opacity(for offset: CGFloat, geometry: GeometryProxy) -> Double {
        let fadeStart: CGFloat = geometry.safeAreaInsets.top + 50 // Adjust this value as needed
        let fadeDistance: CGFloat = 50 // Adjust this value to control how quickly it fades
        
        let elementPosition = scrollOffset - offset
        let opacity = 1.0 - (max(0, elementPosition - fadeStart) / fadeDistance)
        return max(0, min(1, opacity))
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
            
            Button(action: handleEmailAuth) {
                Text(isLogin ? "Log In" : "Sign Up")
                    .frame(width: 160, height: 40)
                    .background(AppColors.buttonBackground)
                    .foregroundColor(AppColors.buttonText)
                    .cornerRadius(20)
                    .font(.system(size: 16, weight: .medium))
            }
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
            
            Spacer()
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
