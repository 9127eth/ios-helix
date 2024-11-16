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
    var isCreating: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true, showDescriptionError: Binding<Bool>, isCreating: Bool = false) {
        self._businessCard = businessCard
        self.showHeader = showHeader
        self._showDescriptionError = showDescriptionError
        self.isCreating = isCreating
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isCreating {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Woo hoo!")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(AppColors.bodyPrimaryText)
                        
                        Image("rocket")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 32)
                            .foregroundColor(AppColors.helixPro)
                    }
                    
                    Text("Let's create a business card.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.bodyPrimaryText)
                        .padding(.bottom, 8)
                    
                    Text("First, give the card a label. Examples include Work, Personal, Side biz, etc.")
                        .font(.body)
                        .foregroundColor(AppColors.bodyPrimaryText)
                }
                .padding(.bottom, 24)
            }
            
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
            
            Text("This is for your reference only and will not be visible on your card when shared. It's only visible in your app.")
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
