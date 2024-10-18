//
//  SubscriptionView.swift
//  Helix
//
//  Created by Richard Waithe on 10/17/24.
//

import SwiftUI

struct SubscriptionView: View {
    @Binding var isPro: Bool
    @State private var selectedPlan: PlanType = .monthly
    @Environment(\.presentationMode) var presentationMode
    
    enum PlanType {
        case monthly, yearly
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pro Plan
                PlanCard(
                    title: "Helix Pro",
                    price: selectedPlan == .monthly ? "$3/month" : "$12/year",
                    features: [
                        "Up to 10 business cards",
                        "Image Upload",
                        "Unlimited sharing",
                        "Custom Card Colors",
                        "CV/Resume Upload"
                    ],
                    isPro: isPro,
                    action: {
                        if !isPro {
                            // Handle subscription action
                            // This is where you'd implement the actual subscription process
                            print("Subscribing to Pro plan")
                        }
                    }
                )
                
                // Plan Toggle
                if !isPro {
                    Picker("Plan", selection: $selectedPlan) {
                        Text("Monthly").tag(PlanType.monthly)
                        Text("Yearly").tag(PlanType.yearly)
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
                        "Image Upload",
                        "Unlimited sharing"
                    ],
                    disabledFeatures: [
                        "Custom Card Colors",
                        "CV/Resume Upload"
                    ],
                    isPro: !isPro,
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
        .background(AppColors.background.edgesIgnoringSafeArea(.all))
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let features: [String]
    var disabledFeatures: [String] = []
    let isPro: Bool
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
                Text(isPro ? "Current Plan" : (title == "Pro" ? "Upgrade" : "Downgrade"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPro ? Color.gray.opacity(0.2) : AppColors.buttonBackground)
                    .foregroundColor(isPro ? .primary : AppColors.buttonText)
                    .cornerRadius(10)
            }
            .disabled(isPro)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
