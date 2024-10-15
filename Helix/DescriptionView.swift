//
//  DescriptionView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct DescriptionView: View {
    @Binding var businessCard: BusinessCard
    @FocusState private var isFocused: Bool
    var showHeader: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showHeader {
                Text("Card Name")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            CustomTextField(title: "", text: $businessCard.description, onCommit: { isFocused = false })
                .focused($isFocused)
                .padding(.bottom, 16)
            
            Text("This is for your reference only and will not be visible on your digital business card. Examples of card names are Work, Personal, etc.")
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
