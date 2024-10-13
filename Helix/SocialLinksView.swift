//
//  SocialLinksView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct SocialLinksView: View {
    @Binding var businessCard: BusinessCard
    @State private var showingAddLinkPopup = false
    @State private var availableSocialLinks: [SocialLinkType] = [.facebook, .instagram, .tiktok, .youtube, .discord, .twitch, .snapchat, .telegram, .whatsapp, .threads]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Social Links")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(SocialLinkType.allCases, id: \.self) { linkType in
                if let linkValue = businessCard.socialLinkValue(for: linkType) {
                    SocialLinkRow(linkType: linkType, value: Binding<String?>(
                        get: { linkValue },
                        set: { newValue in
                            if let newValue = newValue, !newValue.isEmpty {
                                businessCard.updateSocialLink(type: linkType, value: newValue)
                            } else {
                                businessCard.updateSocialLink(type: linkType, value: nil)
                            }
                        }
                    ), onRemove: {
                        businessCard.updateSocialLink(type: linkType, value: nil)
                        availableSocialLinks.append(linkType)
                    })
                }
            }
            
            Button(action: {
                showingAddLinkPopup = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Social Link")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingAddLinkPopup) {
            AddSocialLinkView(availableLinks: $availableSocialLinks, businessCard: $businessCard, isPresented: $showingAddLinkPopup)
        }
    }
}

struct SocialLinkRow: View {
    let linkType: SocialLinkType
    @Binding var value: String?
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Image(linkType.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            CustomTextField(title: linkType.displayName, text: Binding(
                get: { value ?? "" },
                set: { value = $0.isEmpty ? nil : $0 }
            ))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}
