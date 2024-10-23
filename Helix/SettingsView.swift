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
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .padding(.vertical, 8)  // Reduced vertical padding
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
                        .padding(.leading, 16)  // Added left padding
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        Button(action: {
                            // Action to open subscription view (to be implemented)
                        }) {
                            HStack {
                                Text("Subscription")
                                Spacer()
                                Text(isPro ? "Helix Pro \(subscriptionPlanType)" : "Free Plan")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputFieldBackground)
                        }

                        Button(action: {
                            Task {
                                await restorePurchases()
                            }
                        }) {
                            HStack {
                                Text("Restore Purchases")
                                if isRestoringPurchases {
                                    ProgressView()
                                        .tint(AppColors.buttonText)
                                }
                            }
                            .frame(minWidth: 200)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(AppColors.buttonBackground)
                            .foregroundColor(AppColors.buttonText)
                            .cornerRadius(20)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)

                        Divider()

                        Button(action: {
                            authManager.signOut()
                        }) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)  // Reduced vertical padding
                                .padding(.horizontal, 16)
                                .background(AppColors.inputFieldBackground)
                        }

                        Button(action: {
                            print("Delete account button tapped")
                            print("Setting activeAlert to deleteConfirmation")
                            activeAlert = .deleteConfirmation
                            print("activeAlert is now set: \(String(describing: activeAlert))")
                        }) {
                            Text("Delete Account")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(AppColors.inputFieldBackground)
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(8)
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
        print("deleteAccount function called") // Add this debug log
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID found") // Add this debug log
            return
        }
        print("User ID found: \(userId)") // Add this debug log
        
        // First, attempt to delete the account
        Task {
            do {
                // 1. Delete all images from Storage
                let storage = Storage.storage()
                let imagesRef = storage.reference().child("images/\(userId)")
                try? await deleteStorageFolder(reference: imagesRef)
                
                // 2. Delete all documents from Storage
                let docsRef = storage.reference().child("docs/\(userId)")
                try? await deleteStorageFolder(reference: docsRef)
                
                // 3. Delete all business cards from Firestore
                let cardsRef = db.collection("users").document(userId).collection("businessCards")
                let cards = try await cardsRef.getDocuments()
                for card in cards.documents {
                    try await card.reference.delete()
                }
                
                // 4. Finally, attempt to delete the user account
                try await Auth.auth().currentUser?.delete()
                
                // 5. If successful, sign out and reset auth state
                authManager.signOut()
                
            } catch let error as NSError {
                // Handle Firebase Auth errors
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    // Show alert to user that they need to re-authenticate
                    showAlert(
                        title: "Re-authentication Required",
                        message: "For security reasons, please sign out and sign in again before deleting your account.",
                        primaryButton: "Sign Out",
                        primaryAction: {
                            authManager.signOut()
                        }
                    )
                } else {
                    // Show generic error alert
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
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                self.isPro = document.data()?["isPro"] as? Bool ?? false
                
                // Get subscription type from stripeSubscriptionId or similar field
                if let subscriptionId = document.data()?["stripeSubscriptionId"] as? String {
                    // Determine plan type based on subscription ID
                    if subscriptionId.contains("monthly") {
                        self.subscriptionPlanType = "Monthly"
                    } else {
                        self.subscriptionPlanType = "Yearly"
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
