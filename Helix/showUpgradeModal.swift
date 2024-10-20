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

    var body: some View {
        VStack(spacing: 20) {
            Text("Upgrade to Helix Pro")
                .font(.title)
                .fontWeight(.bold)

            Text("Create unlimited business cards and unlock more features with Helix Pro!")
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                showSubscriptionView = true
            }) {
                Text("View Pricing")
                    .foregroundColor(AppColors.buttonText)
                    .padding()
                    .background(AppColors.buttonBackground)
                    .cornerRadius(10)
            }

            Button(action: {
                isPresented = false
            }) {
                Text("Not Now")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView(isPro: .constant(false))
        }
    }
}
