//
//  SubscriptionView.swift
//  Helix
//
//  Created by Richard Waithe on 10/17/24.
//

import SwiftUI
import StoreKit
import Firebase
import FirebaseAuth

struct SubscriptionView: View {
    @Binding var isPro: Bool
    @State private var selectedPlan: PlanType = .lifetime
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var isLoading = true
    @State private var errorMessage: String?
    // Add state for current user plan
    @State private var currentUserPlan: PlanType?
    
    enum PlanType {
        case lifetime
        case yearly
        case monthly
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading products...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Close button
                        HStack {
                            Spacer()
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.primary)
                                    .padding()
                            }
                        }
                        
                        // Plan Toggle
                        if !isPro {
                            Picker("Plan", selection: $selectedPlan) {
                                Text("Lifetime").tag(PlanType.lifetime)
                                Text("Yearly").tag(PlanType.yearly)
                                Text("Monthly").tag(PlanType.monthly)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        } else if isPro && !subscriptionManager.isLifetime {
                            // Show current subscription status without lifetime option
                            Picker("Plan", selection: $selectedPlan) {
                                Text("Yearly").tag(PlanType.yearly)
                                Text("Monthly").tag(PlanType.monthly)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                        
                        // Pro Plan
                        PlanCard(
                            title: "Helix Pro",
                            price: isPro ? (currentUserPlan == .monthly ? "$2.99/month" : 
                                           currentUserPlan == .yearly ? "$12.99/year" : 
                                           "Lifetime Pro") :
                                           (selectedPlan == .monthly ? "$2.99/month" : 
                                            selectedPlan == .yearly ? "$12.99/year" : 
                                            "$19.99 pay once, get Helix Pro forever!"),
                            features: [
                                "Up to 10 business cards",
                                "AI powered business card scanning",
                                "CV/Resume Upload",
                                "Link to physical card via NFC",
                                "Add to Apple Wallet"
                            ],
                            isCurrentPlan: isPro,
                            action: {
                                if !isPro {
                                    purchaseSubscription(for: selectedPlan)
                                }
                            }
                        )
                        
                        // Free Plan
                        PlanCard(
                            title: "Free Plan",
                            price: "$0/year",
                            features: [
                                "1 free business card",
                                "Link to physical card via NFC",
                                "Add to Apple Wallet"
                            ],
                            disabledFeatures: [
                                "Up to 10 business cards",
                                "AI powered business card scanning",
                                "CV/Resume Upload"
                            ],
                            isCurrentPlan: !isPro,
                            action: { } // Empty action since we don't want any downgrade functionality
                        )
                    }
                    .padding()
                }
                .navigationTitle("Helix Pro")
                .background(AppColors.mainSubBackground.edgesIgnoringSafeArea(.all))
            }
        }
        .onAppear {
            Task {
                await loadProducts()
                await loadCurrentPlan()
            }
        }
    }
    
    @MainActor
    private func loadProducts() async {
        isLoading = true
        do {
            try await subscriptionManager.loadProducts()
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    @MainActor
    private func loadCurrentPlan() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let subscriptionId = doc.data()?["stripeSubscriptionId"] as? String {
                // Assuming you store the plan type in the subscription ID or have another field
                // You'll need to adjust this logic based on how you store the plan type
                currentUserPlan = subscriptionId.contains("monthly") ? .monthly : .yearly
            }
        } catch {
            print("Error loading current plan: \(error)")
        }
    }
    
    @MainActor
    private func purchaseSubscription(for planType: PlanType) {
        Task {
            do {
                let productId = switch planType {
                    case .yearly: "001"
                    case .monthly: "002"
                    case .lifetime: "003"
                }
                
                if let product = subscriptionManager.products.first(where: { $0.id == productId }) {
                    try await subscriptionManager.purchase(product)
                    isPro = true
                    presentationMode.wrappedValue.dismiss()
                } else {
                    print("Product not found: \(productId)")
                    errorMessage = "Product not available for purchase."
                }
            } catch {
                print("Failed to purchase: \(error)")
                errorMessage = "Failed to purchase: \(error.localizedDescription)"
            }
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let features: [String]
    var disabledFeatures: [String] = []
    let isCurrentPlan: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(price)
                .font(.title2)
                .fontWeight(.semibold)
            
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text(feature)
                }
            }
            
            ForEach(disabledFeatures, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                    Text(feature)
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: action) {
                HStack {
                    if title == "Helix Pro" && !isCurrentPlan {
                        Image("lightening")
                    }
                    Text(buttonText)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(buttonBackground)
                .foregroundColor(buttonForeground)
                .cornerRadius(10)
            }
            .disabled(isButtonDisabled)
        }
        .padding()
        .background(Color(UIColor.cardSubBackground))
        .cornerRadius(16)
    }
    
    private var buttonText: String {
        if isCurrentPlan {
            return "Current Plan"
        } else if title == "Helix Pro" {
            return "Upgrade"
        } else {
            return "Free Plan"
        }
    }
    
    private var isButtonDisabled: Bool {
        isCurrentPlan || (title == "Free Plan") // Disable button for Free Plan regardless
    }
    
    private var buttonBackground: Color {
        if title == "Helix Pro" && isCurrentPlan {
            return AppColors.buttonBackground
        }
        return isButtonDisabled ? Color.gray.opacity(0.2) : AppColors.buttonBackground
    }
    
    private var buttonForeground: Color {
        if title == "Helix Pro" && isCurrentPlan {
            return AppColors.buttonText
        }
        return isButtonDisabled ? .primary : AppColors.buttonText
    }
}
