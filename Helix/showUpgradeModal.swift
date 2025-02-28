//
//  showUpgradeModal.swift
//  Helix
//
//  Created by Richard Waithe on 10/19/24.
//

import SwiftUI

struct UpgradeModalView: View {
    @Binding var isPresented: Bool
    @State private var showSubscriptionView = false
    @State private var animateContent = false

    var body: some View {
        ZStack {
            // Background blur and overlay
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            // Modal content
            VStack(spacing: 0) {
                // Header with icon
                VStack(spacing: 16) {
                    Image("lightening")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(AppColors.helixPro.opacity(0.15))
                        )
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .opacity(animateContent ? 1.0 : 0)
                    
                    Text("Unlock premium features and remove limits")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.bodyPrimaryText)
                        .opacity(animateContent ? 1.0 : 0)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                
                // Feature highlights
                VStack(spacing: 20) {
                    Text("With Helix Pro you get:")
                        .font(.headline)
                        .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "checkmark.circle.fill", text: "Create up to 10 business cards")
                        FeatureRow(icon: "checkmark.circle.fill", text: "AI powered business card scanning")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Upload your CV/Resume")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Plus exciting new features coming soon")
                            .opacity(0.8)
                    }
                    .padding(.horizontal, 20)
                }
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1.0 : 0)
                
                Spacer()
                    .frame(height: 20)
                
                // Call to action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showSubscriptionView = true
                    }) {
                        HStack {
                            Image("lightening")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            
                            Text("View Pricing")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.helixPro)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: AppColors.helixPro.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Maybe Later")
                            .foregroundColor(AppColors.bodyPrimaryText.opacity(0.6))
                            .padding(.vertical, 4) // Reduced vertical padding
                    }
                }
                .offset(y: animateContent ? 0 : 30)
                .opacity(animateContent ? 1.0 : 0)
                .padding(.bottom, 20) // Reduced bottom padding
            }
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.cardSubBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(animateContent ? 1.0 : 0.9)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView(isPro: .constant(false))
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.helixPro)
                .font(.system(size: 16))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.bodyPrimaryText)
            
            Spacer()
        }
    }
}

struct UpgradeModalView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            UpgradeModalView(isPresented: .constant(true))
        }
    }
}
