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
        VStack(alignment: .leading, spacing: 16) {
            ForEach(businessCard.webLinks ?? [], id: \.url) { link in
                HStack {
                    Text(link.displayText)
                    Spacer()
                    Text(link.url)
                }
            }
            
            TextField("URL", text: $newLinkUrl)
            TextField("Display Text", text: $newLinkDisplayText)
            
            Button("Add Link") {
                if !newLinkUrl.isEmpty && !newLinkDisplayText.isEmpty {
                    let newLink = WebLink(url: newLinkUrl, displayText: newLinkDisplayText)
                    businessCard.webLinks = (businessCard.webLinks ?? []) + [newLink]
                    newLinkUrl = ""
                    newLinkDisplayText = ""
                }
            }
        }
    }
}