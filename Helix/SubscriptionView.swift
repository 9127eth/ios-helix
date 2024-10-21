//
//  SubscriptionView.swift
//  Helix
//
//  Created by Richard Waithe on 10/17/24.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Binding var isPro: Bool
    @State private var selectedPlan: PlanType = .yearly
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    enum PlanType {
        case yearly, monthly
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
                        
                        // Pro Plan
                        PlanCard(
                            title: "Helix Pro",
                            price: selectedPlan == .monthly ? "$2.99/month" : "$12.99/year",
                            features: [
                                "Up to 10 business cards",
                                "CV/Resume Upload",
                                "Link to physical card via NFC",
                                "Image Upload"
                            ],
                            isCurrentPlan: isPro,
                            action: {
                                if !isPro {
                                    purchaseSubscription(for: selectedPlan)
                                }
                            }
                        )
                        
                        // Plan Toggle
                        if !isPro {
                            Picker("Plan", selection: $selectedPlan) {
                                Text("Yearly").tag(PlanType.yearly)
                                Text("Monthly").tag(PlanType.monthly)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                        
                        // Free Plan
                        PlanCard(
                            title: "Free Plan",
                            price: "$0/year",
                            features: [
                                "1 free business card",
                                "Link to physical card via NFC",
                                "Image Upload"
                            ],
                            disabledFeatures: [
                                "Up to 10 business cards",
                                "CV/Resume Upload"
                            ],
                            isCurrentPlan: !isPro,
                            action: {
                                if isPro {
                                    // Handle downgrade action
                                    // This is where you'd implement the actual downgrade process
                                    print("Downgrading to Free plan")
                                }
                            }
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
    private func purchaseSubscription(for planType: PlanType) {
        Task {
            do {
                let productId = planType == .yearly ? "001" : "002" // Updated product IDs
                if let product = subscriptionManager.products.first(where: { $0.id == productId }) {
                    try await subscriptionManager.purchase(product)
                    isPro = true
                    presentationMode.wrappedValue.dismiss()
                } else {
                    print("Product not found: \(productId)")
                    errorMessage = "Product not available for purchase."
                }
            } catch {
                print("Failed to purchase subscription: \(error)")
                errorMessage = "Failed to purchase subscription: \(error.localizedDescription)"
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
                Text(buttonText)
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
            return "Free"
        }
    }
    
    private var isButtonDisabled: Bool {
        isCurrentPlan
    }
    
    private var buttonBackground: Color {
        isButtonDisabled ? Color.gray.opacity(0.2) : AppColors.buttonBackground
    }
    
    private var buttonForeground: Color {
        isButtonDisabled ? .primary : AppColors.buttonText
    }
}
