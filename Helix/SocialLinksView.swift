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

    @State private var localValue: String
    @State private var offset: CGFloat = 0
    @FocusState private var isFieldFocused: Bool

    init(
        linkType: SocialLinkType,
        value: Binding<String?>,
        isFocused: Bool,
        onCommit: @escaping () -> Void
    ) {
        self.linkType = linkType
        self._value = value
        self.isFocused = isFocused
        self.onCommit = onCommit
        
        // Initialize localValue with the base URL if value is empty
        if let existingValue = value.wrappedValue, !existingValue.isEmpty {
            _localValue = State(initialValue: existingValue)
        } else {
            _localValue = State(initialValue: linkType.baseURL)
        }
    }

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
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                    .frame(width: 60, height: geometry.size.height)
                    .offset(x: offset + 60)
                }
                .frame(height: geometry.size.height, alignment: .center)
            }
            
            HStack {
                Image(linkType.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                TextField("Enter your \(linkType.displayName) URL", text: $localValue, onCommit: onCommit)
                    .focused($isFieldFocused)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(.vertical, 8)
            .padding(.leading, 16)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { gesture in
                        if abs(gesture.translation.width) > abs(gesture.translation.height) {
                            offset = min(0, gesture.translation.width)
                        }
                    }
                    .onEnded { gesture in
                        withAnimation {
                            if gesture.translation.width < -50 {
                                offset = -60
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .onChange(of: localValue) { newValue in
            value = newValue
        }
        .onAppear {
            isFieldFocused = isFocused
        }
    }
}
