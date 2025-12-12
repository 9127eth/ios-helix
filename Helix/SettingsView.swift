//
//  SettingsView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage

struct SmallToggleStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                configuration.label
                Spacer()
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .fill(configuration.isOn ? Color.green : Color.gray)
                    .frame(width: 40, height: 24)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .padding(2)
                            .offset(x: configuration.isOn ? 8 : -8)
                    )
                    .animation(.spring(), value: configuration.isOn)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isAuthenticated: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var scrollOffset: CGFloat = 0  // Track scroll offset
    @State private var isPro: Bool = false
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var isRestoringPurchases = false
    @State private var restoreError: String?
    @State private var subscriptionPlanType: String = ""
    @State private var activeAlert: AlertType?
    @State private var showingFAQ = false
    @State private var showingContact = false
    @State private var showChangeEmail = false
    @State private var showChangePassword = false
    @State private var newEmail = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showSuccessMessage = false
    @State private var isProcessing = false
    @State private var currentPasswordError = false
    @State private var currentPasswordErrorMessage = ""
    @State private var newPasswordError = false
    @State private var newPasswordErrorMessage = ""
    @State private var confirmPasswordError = false
    @State private var confirmPasswordErrorMessage = ""
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showSubscriptionView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                    .opacity(headerOpacity)  // Apply fade-out effect

                VStack(spacing: 0) {
                    // Appearance Section
                    Text("Appearance")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 10)
                        .padding(.leading, 16)  // Added left padding
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        Toggle(isOn: $isDarkMode) {
                            HStack {
                                Image("Sun")
                                    .foregroundColor(AppColors.foreground)
                                Text("Dark Mode")
                            }
                        }
                        .toggleStyle(SmallToggleStyle())
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(AppColors.inputFieldBackground)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .padding(.bottom, 20)

                    // Account Section
                    Text("Account")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 10)
                        .padding(.leading, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        // Email and Sign-in method display
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(AppColors.foreground)
                            Text("Email Address:")
                                .foregroundColor(AppColors.foreground)
                            Spacer()
                            Text(Auth.auth().currentUser?.email ?? "Not available")
                                .foregroundColor(AppColors.foreground)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(AppColors.inputFieldBackground)
                        
                        // Add verification status right after email
                   if let user = Auth.auth().currentUser, !user.isEmailVerified {
                            Button(action: {
                                Task {
                                    do {
                                        try await user.sendEmailVerification()
                                        alertTitle = "Verification Email Sent"
                                        alertMessage = "Please check your email to verify your account"
                                        showAlert = true
                                    } catch {
                                        alertTitle = "Error"
                                        alertMessage = error.localizedDescription
                                        showAlert = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.yellow)
                                    Text("Please verify your email")
                                        .foregroundColor(AppColors.foreground)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.foreground)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(AppColors.inputFieldBackground)
                            }
                        }
                        
                        // Sign-in method display
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(AppColors.foreground)
                            Text("Signed in with:")
                                .foregroundColor(AppColors.foreground)
                            Spacer()
                            Text(getSignInMethod())
                                .foregroundColor(AppColors.foreground)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(AppColors.inputFieldBackground)

                        // Conditionally show email/password change buttons
                        if getSignInMethod() == "Email" {
                            Button(action: {
                                showChangeEmail = true
                            }) {
                                HStack {
                                    Image(systemName: "envelope.badge")
                                        .foregroundColor(AppColors.foreground)
                                    Text("Change Email")
                                        .foregroundColor(AppColors.foreground)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(AppColors.inputFieldBackground)
                            }
                            
                            Button(action: {
                                showChangePassword = true
                            }) {
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(AppColors.foreground)
                                    Text("Change Password")
                                        .foregroundColor(AppColors.foreground)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(AppColors.inputFieldBackground)
                            }
                        }
                        
                        // Modern divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 1)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(AppColors.inputFieldBackground))

                        // Sign out button
                        Button(action: {
                            authManager.signOut()
                        }) {
                            HStack {
                                Image("signOut")
                                    .foregroundColor(AppColors.foreground)
                                Text("Sign Out")
                                    .foregroundColor(AppColors.foreground)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputFieldBackground)
                        }

                        // Delete account button
                        Button(action: {
                            print("Delete account button tapped")
                            activeAlert = .deleteConfirmation
                        }) {
                            HStack {
                                Image("trashWarning")
                                    .foregroundColor(.red)
                                Text("Delete Account")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputFieldBackground)
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .padding(.bottom, 20)

                    // New Subscription Section
                    HStack {
                        Text("Subscription")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !isPro {
                            Button(action: {
                                showSubscriptionView = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "bolt.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 12, height: 12)
                                    Text("Get Helix Pro")
                                        .font(.subheadline)
                                }
                                .foregroundColor(AppColors.helixPro)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.gray.opacity(0.10))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        Button(action: {
                            // Action to open subscription view
                        }) {
                            HStack {
                                Image("subscription")
                                    .foregroundColor(AppColors.foreground)
                                Text("Current Plan:")
                                    .foregroundColor(AppColors.foreground)
                                Spacer()
                                Text(isPro ? "Helix Pro \(subscriptionPlanType)" : "Free Plan")
                                    .foregroundColor(AppColors.foreground)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputFieldBackground)
                        }

                        Button(action: {
                            Task {
                                await restorePurchases()
                            }
                        }) {
                            HStack {
                                Image("restore")
                                    .foregroundColor(AppColors.foreground)
                                Text("Restore Purchases")
                                    .foregroundColor(AppColors.foreground)
                                Spacer()
                                if isRestoringPurchases {
                                    ProgressView()
                                        .tint(AppColors.buttonText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputFieldBackground)
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .padding(.bottom, 20)

                    // Support Section
                    Text("Support")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 10)
                        .padding(.leading, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)

                    VStack(spacing: 0) {
                        Button(action: {
                            showingFAQ = true
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(AppColors.foreground)
                                Text("FAQ")
                                    .foregroundColor(AppColors.foreground)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputFieldBackground)
                        }

                        Button(action: {
                            showingContact = true
                        }) {
                            HStack {
                                Image(systemName: "message")
                                    .foregroundColor(AppColors.foreground)
                                Text("Contact Us")
                                    .foregroundColor(AppColors.foreground)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputFieldBackground)
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .padding(.bottom, 20)

                    VStack(spacing: 8) {
                        Text("Version 1.4.5")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Button(action: {
                                showingPrivacyPolicy = true
                            }) {
                                Text("Privacy")
                                    .font(.footnote)
                                    .foregroundColor(AppColors.bodyPrimaryText)
                            }
                            
                            Text("&")
                                .font(.footnote)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showingTerms = true
                            }) {
                                Text("Terms")
                                    .font(.footnote)
                                    .foregroundColor(AppColors.bodyPrimaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    }
                }
            }
            .padding()
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScrollOffsetKey.self, value: -proxy.frame(in: .named("scroll")).origin.y)
                }
            )
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                self.scrollOffset = value
            }
        }
        .coordinateSpace(name: "scroll")
        .background(AppColors.background)
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .deleteConfirmation:
                return Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your account? This action is irreversible."),
                    primaryButton: .destructive(Text("Delete")) {
                        print("Delete confirmed in alert")
                        deleteAccount()
                    },
                    secondaryButton: .cancel()
                )
            case .restoreError(let message):
                return Alert(
                    title: Text("Restore Failed"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear(perform: fetchUserProStatus)
        .sheet(isPresented: $showingFAQ) {
            FAQView()
        }
        .sheet(isPresented: $showingContact) {
            ContactView()
        }
        .sheet(isPresented: $showChangeEmail) {
            NavigationView {
                VStack {
                    Spacer()
                        .frame(height: 80) // Add space at the top
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            CustomTextField(title: "Current Password", text: $currentPassword, isSecure: true)
                                .frame(width: 280)
                            CustomTextField(title: "New Email", text: $newEmail)
                                .frame(width: 280)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                            
                            Button(action: {
                                Task {
                                    await changeEmail()
                                }
                            }) {
                                Text("Update Email")
                                    .font(.system(size: 15, weight: .medium))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            }
                            .background(AppColors.buttonBackground)
                            .foregroundColor(AppColors.buttonText)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .navigationTitle("Change Email")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showChangeEmail = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showChangePassword, onDismiss: {
            // Reset all states when sheet is dismissed
            showSuccessMessage = false
            isProcessing = false
            newPassword = ""
            confirmPassword = ""
            currentPassword = ""
        }) {
            NavigationView {
                ZStack {
                    VStack {
                        Spacer()
                            .frame(height: 80) // Add space at the top
                        
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 20) {
                                if !showSuccessMessage {
                                    CustomTextField(title: "Current Password", text: $currentPassword, isSecure: true)
                                        .frame(width: 280)
                                    CustomTextField(title: "New Password", text: $newPassword, isSecure: true)
                                        .frame(width: 280)
                                    CustomTextField(title: "Confirm New Password", text: $confirmPassword, isSecure: true)
                                        .frame(width: 280)
                                    
                                    Button(action: {
                                        Task {
                                            await changePassword()
                                        }
                                    }) {
                                        if isProcessing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.buttonText))
                                                .frame(height: 20)
                                        } else {
                                            Text("Update Password")
                                                .font(.system(size: 15, weight: .medium))
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 8)
                                        }
                                    }
                                    .disabled(isProcessing)
                                    .background(AppColors.buttonBackground)
                                    .foregroundColor(AppColors.buttonText)
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 8)
                                    
                                    Button(action: handleForgotPassword) {
                                        Text("Forgot password?")
                                            .font(.footnote)
                                            .foregroundColor(AppColors.bodyPrimaryText)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    
                    if showSuccessMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(AppColors.buttonBackground)
                            
                            Text("Password Updated Successfully!")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .navigationTitle("Change Password")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !showSuccessMessage {
                            Button("Cancel") {
                                showChangePassword = false
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: showSuccessMessage)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertTitle == "Success" {
                        showChangeEmail = false
                        showChangePassword = false
                    }
                }
            )
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            SafariView(url: URL(string: "https://www.helixcard.app/privacy-policy")!)
        }
        .sheet(isPresented: $showingTerms) {
            SafariView(url: URL(string: "https://www.helixcard.app/terms-of-service")!)
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView(isPro: $isPro)
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }

    // Calculate opacity based on scroll offset
    private var headerOpacity: Double {
        let opacity = 1.0 - Double(scrollOffset) / 100.0
        return max(0, min(1, opacity))
    }

    private func deleteAccount() {
        print("deleteAccount function called")
        guard let user = Auth.auth().currentUser else {
            print("No user found")
            return
        }
        
        Task {
            do {
                // First, attempt to delete the user account to check authentication
                try await user.delete()
                
                // If delete succeeds, then proceed with cleaning up data
                let userId = user.uid
                let storage = Storage.storage()
                let db = Firestore.firestore()
                
                // Delete storage items
                let imagesRef = storage.reference().child("images/\(userId)")
                try? await deleteStorageFolder(reference: imagesRef)
                
                let docsRef = storage.reference().child("docs/\(userId)")
                try? await deleteStorageFolder(reference: docsRef)
                
                // Delete Firestore documents
                let cardsRef = db.collection("users").document(userId).collection("businessCards")
                let cards = try await cardsRef.getDocuments()
                for card in cards.documents {
                    try await card.reference.delete()
                }
                
                // Delete user document
                try await db.collection("users").document(userId).delete()
                
                // Finally, sign out
                authManager.signOut()
                
            } catch let error as NSError {
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    showAlert(
                        title: "Re-authentication Required",
                        message: "For security reasons, please sign out and sign in again before deleting your account.",
                        primaryButton: "Sign Out",
                        primaryAction: {
                            authManager.signOut()
                        }
                    )
                } else {
                    showAlert(
                        title: "Error",
                        message: "Failed to delete account: \(error.localizedDescription)",
                        primaryButton: "OK"
                    )
                }
            }
        }
    }

    private func deleteStorageFolder(reference: StorageReference) async throws {
        do {
            let items = try await reference.listAll()
            
            // Delete all items in parallel
            try await withThrowingTaskGroup(of: Void.self) { group in
                for item in items.items {
                    group.addTask {
                        try await item.delete()
                    }
                }
                
                // Wait for all deletions to complete
                try await group.waitForAll()
            }
        } catch {
            print("Error deleting storage folder: \(error.localizedDescription)")
            // We're using try? in the calling function, so this error will be ignored
            throw error
        }
    }

    private func showAlert(title: String, message: String, primaryButton: String, primaryAction: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: primaryButton, style: .default) { _ in
            primaryAction?()
        }
        alert.addAction(action)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private func fetchUserProStatus() {
        // Refresh current user to get latest email verification status
        Auth.auth().currentUser?.reload { _ in
            // This will trigger a view update since we're checking isEmailVerified in the view
        }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                self.isPro = document.data()?["isPro"] as? Bool ?? false
                
                // Get subscription type directly from isProType
                if let proType = document.data()?["isProType"] as? String {
                    switch proType {
                        case "monthly":
                            self.subscriptionPlanType = "Monthly"
                        case "yearly":
                            self.subscriptionPlanType = "Yearly"
                        case "lifetime":
                            self.subscriptionPlanType = "Lifetime"
                        default:
                            self.subscriptionPlanType = ""
                    }
                }
            }
        }
    }

    private func restorePurchases() async {
        isRestoringPurchases = true
        restoreError = nil
        do {
            try await subscriptionManager.restorePurchases()
            isPro = !subscriptionManager.purchasedSubscriptions.isEmpty
        } catch {
            restoreError = error.localizedDescription
        }
        isRestoringPurchases = false
    }

    private func getSignInMethod() -> String {
        guard let user = Auth.auth().currentUser else { return "Unknown" }
        
        if user.providerData.isEmpty { return "Unknown" }
        
        let providerId = user.providerData[0].providerID
        switch providerId {
        case "google.com":
            return "Google"
        case "apple.com":
            return "Apple ID"
        case "password":
            return "Email"
        default:
            return "Unknown"
        }
    }

    private func changeEmail() async {
        guard let user = Auth.auth().currentUser else { return }
        
        // Basic email validation
        guard isValidEmail(newEmail) else {
            alertTitle = "Invalid Email"
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        do {
            // Create credentials for reauthentication
            let credential = EmailAuthProvider.credential(
                withEmail: user.email ?? "",
                password: currentPassword
            )
            
            // Reauthenticate
            try await user.reauthenticate(with: credential)
            
            // Send verification email before updating
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
            
            // Show success message
            alertTitle = "Verification Email Sent"
            alertMessage = "Please check your email at \(newEmail) to verify and complete the email change"
            showAlert = true
            
            // Clear form
            newEmail = ""
            currentPassword = ""
            showChangeEmail = false
            
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.wrongPassword.rawValue:
                alertTitle = "Incorrect Password"
                alertMessage = "The current password you entered is incorrect"
            case AuthErrorCode.invalidEmail.rawValue:
                alertTitle = "Invalid Email"
                alertMessage = "Please enter a valid email address"
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                alertTitle = "Email In Use"
                alertMessage = "This email is already associated with another account"
            default:
                alertTitle = "Error"
                alertMessage = error.localizedDescription
            }
            showAlert = true
        }
    }

    private func changePassword() async {
        // Reset error states
        currentPasswordError = false
        newPasswordError = false
        confirmPasswordError = false
        
        // Validate new password
        guard isValidPassword(newPassword) else {
            newPasswordError = true
            newPasswordErrorMessage = "Password must be at least 6 characters long"
            return
        }
        
        // Check if passwords match
        guard newPassword == confirmPassword else {
            confirmPasswordError = true
            confirmPasswordErrorMessage = "Passwords don't match"
            return
        }
        
        isProcessing = true
        
        do {
            guard let user = Auth.auth().currentUser,
                  let email = user.email else {
                return
            }
            
            let credential = EmailAuthProvider.credential(
                withEmail: email,
                password: currentPassword
            )
            
            // Try to reauthenticate first
            do {
                try await user.reauthenticate(with: credential)
            } catch let error as NSError {
                isProcessing = false
                if error.domain == AuthErrorDomain {
                    currentPasswordError = true
                    currentPasswordErrorMessage = "Current password is incorrect"
                } else {
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
                return
            }
            
            // If we get here, reauthentication was successful
            // Now try to update the password
            try await user.updatePassword(to: newPassword)
            
            showSuccessMessage = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showChangePassword = false
            }
            
        } catch let error as NSError {
            isProcessing = false
            if error.domain == AuthErrorDomain {
                switch error.code {
                case 17026: // Weak password error code
                    newPasswordError = true
                    newPasswordErrorMessage = "Please choose a stronger password"
                default:
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
        
        isProcessing = false
    }

    // Add these helper functions
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }

    private func handleForgotPassword() {
        guard let email = Auth.auth().currentUser?.email else { return }
        
        authManager.resetPassword(email: email) { result in
            switch result {
            case .success:
                alertTitle = "Password Reset Email Sent"
                alertMessage = "Please check your email for instructions to reset your password"
                showAlert = true
                showChangePassword = false
            case .failure(let error):
                alertTitle = "Error"
                alertMessage = "Failed to send password reset email: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

// Helper to track scroll offset
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

struct RestoreError: Identifiable {
    let id = UUID()
    let message: String
}

enum AlertType: Identifiable {
    case deleteConfirmation
    case restoreError(String)
    
    var id: Int {
        switch self {
        case .deleteConfirmation:
            return 0
        case .restoreError:
            return 1
        }
    }
}
