//
//  WebLinksView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct WebLinksView: View {
    @Binding var businessCard: BusinessCard
    @State private var newLinkUrl = ""
    @State private var newLinkDisplayText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(businessCard.webLinks ?? [], id: \.url) { link in
                HStack {
                    Text(link.displayText)
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text(link.url)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            CustomTextField(title: "URL", text: $newLinkUrl)
            CustomTextField(title: "Display Text", text: $newLinkDisplayText)
            
            Button(action: addNewLink) {
                Text("Add Link")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.primary)
                    .cornerRadius(20)
            }
        }
    }
    
    private func addNewLink() {
        if !newLinkUrl.isEmpty && !newLinkDisplayText.isEmpty {
            let newLink = WebLink(url: newLinkUrl, displayText: newLinkDisplayText)
            businessCard.webLinks = (businessCard.webLinks ?? []) + [newLink]
            newLinkUrl = ""
            newLinkDisplayText = ""
        }
    }
}
