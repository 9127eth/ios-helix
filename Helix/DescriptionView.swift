//
//  DescriptionView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct DescriptionView: View {
    @Binding var businessCard: BusinessCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Card Name")
                .font(.headline)
                .padding(.bottom, 8)
            
            CustomTextField(title: "", text: $businessCard.description)
                .padding(.bottom, 16)
            
            Text("This is for your reference only and will not be visible on your digital business card. Examples of card names are Work, Personal, etc.")
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }
}
