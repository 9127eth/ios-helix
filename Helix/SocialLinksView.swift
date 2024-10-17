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
    var showHeader: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Social Links")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
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
                Text("Add Social Link")
                    .foregroundColor(AppColors.buttonText)
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.buttonBackground)
                    .cornerRadius(16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .padding(.top, showHeader ? 0 : 16)
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
    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            localValue = ""
                            value = nil
                            onCommit()
                            offset = 0
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                    .frame(width: 60, height: geometry.size.height) // Ensure height matches the row
                    .offset(x: offset + 60)
                }
                .frame(height: geometry.size.height, alignment: .center) // Align center vertically
            }
            
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
            }
            .padding(.vertical, 8)
            .background(Color.clear)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { gesture in
                        if abs(gesture.translation.width) > abs(gesture.translation.height) {
                            offset = min(0, gesture.translation.width)
                        }
                    }
                    .onEnded { gesture in
                        withAnimation {
                            if gesture.translation.width < -50 && abs(gesture.translation.width) > abs(gesture.translation.height) {
                                offset = -60
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
    }
}
