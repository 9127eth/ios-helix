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
        VStack(alignment: .leading, spacing: 20) {
            Text("Description")
                .font(.headline)
            CustomTextEditor(title: "Card Description", text: $businessCard.description)
        }
    }
}
