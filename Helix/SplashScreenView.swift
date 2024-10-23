//
//  SplashScreenView.swift
//  Helix
//
//  Created by Richard Waithe on 10/23/24.
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image("helix_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                
                Text("A business card that creates memorable connections.")
                    .font(.title2)
                    .foregroundColor(AppColors.bodyPrimaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
