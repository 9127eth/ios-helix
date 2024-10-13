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
    @FocusState private var focusedLink: SocialLinkType?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Social Links")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(Array(businessCard.socialLinks.keys), id: \.self) { linkType in
                SocialLinkRow(
                    linkType: linkType,
                    value: Binding(
                        get: { businessCard.socialLinks[linkType] ?? "" },
                        set: { newValue in
                            if let newValue = newValue {
                                let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedValue.isEmpty {
                                    businessCard.socialLinks[linkType] = trimmedValue
                                } else {
                                    businessCard.socialLinks.removeValue(forKey: linkType)
                                }
                            } else {
                                businessCard.socialLinks.removeValue(forKey: linkType)
                            }
                        }
                    ),
                    isFocused: focusedLink == linkType,
                    onCommit: {
                        if let currentIndex = Array(businessCard.socialLinks.keys).firstIndex(of: linkType),
                           currentIndex < businessCard.socialLinks.count - 1 {
                            focusedLink = Array(businessCard.socialLinks.keys)[currentIndex + 1]
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
                selectedLinks: Binding(
                    get: { Set(businessCard.socialLinks.keys) },
                    set: { newSelectedLinks in
                        for linkType in SocialLinkType.allCases {
                            if newSelectedLinks.contains(linkType) && !businessCard.socialLinks.keys.contains(linkType) {
                                businessCard.socialLinks[linkType] = ""
                            } else if !newSelectedLinks.contains(linkType) && businessCard.socialLinks.keys.contains(linkType) {
                                businessCard.socialLinks.removeValue(forKey: linkType)
                            }
                        }
                    }
                ),
                isPresented: $showingAddLinkPopup
            )
        }
        .onAppear {
            if businessCard.socialLinks.isEmpty {
                businessCard.socialLinks[.twitter] = ""
                businessCard.socialLinks[.linkedIn] = ""
            }
        }
    }
}

struct SocialLinkRow: View {
    let linkType: SocialLinkType
    @Binding var value: String?
    let isFocused: Bool
    let onCommit: () -> Void

    @State private var localValue: String = ""

    var body: some View {
        HStack {
            Image(linkType.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            CustomTextField(title: linkType.displayName, text: $localValue)
                .onAppear {
                    localValue = value ?? ""
                }
                .onChange(of: localValue) { newValue in
                    value = newValue.isEmpty ? nil : newValue
                }
                .onSubmit(onCommit)
            Button(action: {
                localValue = ""
                value = nil
                onCommit()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}
