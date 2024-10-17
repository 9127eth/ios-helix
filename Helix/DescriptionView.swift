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
    @Binding var showDescriptionError: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true, showDescriptionError: Binding<Bool>) {
        self._businessCard = businessCard
        self.showHeader = showHeader
        self._showDescriptionError = showDescriptionError
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showHeader {
                Text("Card Label*")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            ErrorTextField(
                title: "",
                text: $businessCard.description,
                showError: $showDescriptionError,
                placeholder: "Work, Personal, Side Biz, etc...",
                onCommit: { isFocused = false }
            )
            .focused($isFocused)
            .padding(.bottom, 16)
            
            Text("This is for your reference only and will not be visible on your digital business card. Examples of card names are Work, Personal, etc.")
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// Update the preview provider if you have one
struct DescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        DescriptionView(businessCard: .constant(BusinessCard(cardSlug: "", firstName: "")), showDescriptionError: .constant(false))
    }
}
