//
//  BusinessCardView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//

import SwiftUI

struct BusinessCardGridView: View {
    let businessCards: [BusinessCard]
    @Binding var showCreateCard: Bool
    
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(businessCards) { card in
                    BusinessCardItemView(card: card)
                }
                AddCardButton(action: { showCreateCard = true })
            }
            .padding()
        }
        .background(AppColors.background)
    }
}
