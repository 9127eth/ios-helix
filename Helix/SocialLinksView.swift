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
    @State private var availableSocialLinks: [SocialLinkType] = SocialLinkType.allCases
    @State private var selectedLinks: Set<SocialLinkType> = [.twitter, .linkedIn]
    @FocusState private var focusedLink: SocialLinkType?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Social Links")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(Array(selectedLinks), id: \.self) { linkType in
                SocialLinkRow(
                    linkType: linkType,
                    value: Binding(
                        get: { businessCard.socialLinkValue(for: linkType) ?? "" },
                        set: { newValue in
                            if let newValue = newValue {
                                let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedValue.isEmpty {
                                    businessCard.updateSocialLink(type: linkType, value: trimmedValue)
                                } else {
                                    businessCard.removeSocialLink(linkType)
                                }
                            } else {
                                businessCard.removeSocialLink(linkType)
                            }
                        }
                    ),
                    isFocused: focusedLink == linkType,
                    onCommit: {
                        if let currentIndex = Array(selectedLinks).firstIndex(of: linkType),
                           currentIndex < selectedLinks.count - 1 {
                            focusedLink = Array(selectedLinks)[currentIndex + 1]
                        } else {
                            focusedLink = nil
                        }
                    }
                )
                .focused($focusedLink, equals: linkType)
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
            AddSocialLinkView(
                availableLinks: $availableSocialLinks,
                selectedLinks: $selectedLinks,
                isPresented: $showingAddLinkPopup
            )
        }
    }
}

struct SocialLinkRow: View {
    let linkType: SocialLinkType
    @Binding var value: String?
    let isFocused: Bool
    let onCommit: () -> Void

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
            .onSubmit(onCommit)
            Button(action: {
                value = nil
                onCommit()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}
