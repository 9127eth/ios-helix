//
//  BusinessCardView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//

import SwiftUI

struct BusinessCardGridView: View {
    @Binding var businessCards: [BusinessCard]
    @Binding var showCreateCard: Bool
    
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                
                Spacer(minLength: UIScreen.main.bounds.height * 0.07)
                
                LazyVStack(spacing: 16) {
                    ForEach($businessCards) { $card in
                        BusinessCardItemView(card: $card)
                    }
                    AddCardButton(action: { showCreateCard = true })
                }
            }
            .padding()
        }
        .background(AppColors.background)
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Business Cards")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You must be the change you wish to see in the world. -Mahatma Gandhi")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
}
