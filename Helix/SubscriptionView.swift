//
//  SubscriptionView.swift
//  Helix
//
//  Created by Richard Waithe on 10/17/24.
//

import SwiftUI

struct SubscriptionView: View {
    @Binding var isPro: Bool
    @State private var selectedPlan: PlanType = .yearly
    @Environment(\.presentationMode) var presentationMode
    
    enum PlanType {
        case yearly, monthly
    }
    
    var body: some View {
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
        .background(AppColors.mainSubBackground.edgesIgnoringSafeArea(.all))
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
        if isPro {
            return title == "Helix Pro" ? "Current Plan" : "Free"
        } else {
            return title == "Helix Pro" ? "Upgrade" : "Curent Plan"
        }
    }
    
    private var isButtonDisabled: Bool {
        isPro
    }
    
    private var buttonBackground: Color {
        isPro ? Color.gray.opacity(0.2) : AppColors.buttonBackground
    }
    
    private var buttonForeground: Color {
        isPro ? .primary : AppColors.buttonText
    }
}
