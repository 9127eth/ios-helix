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
    @State private var visibleLinkTypes: [SocialLinkType] = []
    var showHeader: Bool
    @State private var offsets: [CGFloat] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Social Links")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            ForEach(visibleLinkTypes.indices, id: \.self) { index in
                let linkType = visibleLinkTypes[index]
                ZStack {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Spacer()
                            Button(action: {
                                setValue(nil, for: linkType)
                                visibleLinkTypes.removeAll { $0 == linkType }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                            }
                            .frame(width: 60, height: geometry.size.height)
                            .offset(x: offsets[index] + 60)
                        }
                        .frame(height: geometry.size.height, alignment: .center)
                    }
                    
                    SocialLinkRow(
                        linkType: linkType,
                        value: binding(for: linkType)
                    )
                    .offset(x: offsets[index])
                    .gesture(
                        DragGesture(minimumDistance: 20, coordinateSpace: .local)
                            .onChanged { gesture in
                                if abs(gesture.translation.width) > abs(gesture.translation.height) {
                                    offsets[index] = min(0, gesture.translation.width)
                                }
                            }
                            .onEnded { gesture in
                                withAnimation {
                                    if gesture.translation.width < -50 && abs(gesture.translation.width) > abs(gesture.translation.height) {
                                        offsets[index] = -60
                                    } else {
                                        offsets[index] = 0
                                    }
                                }
                            }
                    )
                }
            }
            
            Button(action: { showingAddLinkPopup = true }) {
                Text("Add Another Link")
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
                availableLinks: .constant(SocialLinkType.allCases.filter { !visibleLinkTypes.contains($0) }),
                selectedLinks: Binding(
                    get: { Set(self.visibleLinkTypes) },
                    set: { newLinks in
                        self.visibleLinkTypes = Array(newLinks)
                        updateVisibleLinkTypes()
                        updateOffsets() // Add this line
                    }
                ),
                isPresented: $showingAddLinkPopup,
                onLinksUpdated: {
                    updateVisibleLinkTypes()
                }
            )
        }
        .onAppear {
            updateVisibleLinkTypes()
            updateOffsets()
        }
        .onChange(of: visibleLinkTypes) { _ in
            updateOffsets()
        }
    }

    private func binding(for linkType: SocialLinkType) -> Binding<String> {
        Binding(
            get: { self.getValue(for: linkType) ?? "" },
            set: { self.setValue($0, for: linkType) }
        )
    }

    private func getValue(for linkType: SocialLinkType) -> String? {
        switch linkType {
        case .linkedIn: return businessCard.linkedIn
        case .twitter: return businessCard.twitter
        case .facebook: return businessCard.facebookUrl
        case .instagram: return businessCard.instagramUrl
        case .tiktok: return businessCard.tiktokUrl
        case .youtube: return businessCard.youtubeUrl
        case .discord: return businessCard.discordUrl
        case .twitch: return businessCard.twitchUrl
        case .snapchat: return businessCard.snapchatUrl
        case .telegram: return businessCard.telegramUrl
        case .whatsapp: return businessCard.whatsappUrl
        case .threads: return businessCard.threadsUrl
        }
    }

    private func setValue(_ value: String?, for linkType: SocialLinkType) {
        switch linkType {
        case .linkedIn: businessCard.linkedIn = value
        case .twitter: businessCard.twitter = value
        case .facebook: businessCard.facebookUrl = value
        case .instagram: businessCard.instagramUrl = value
        case .tiktok: businessCard.tiktokUrl = value
        case .youtube: businessCard.youtubeUrl = value
        case .discord: businessCard.discordUrl = value
        case .twitch: businessCard.twitchUrl = value
        case .snapchat: businessCard.snapchatUrl = value
        case .telegram: businessCard.telegramUrl = value
        case .whatsapp: businessCard.whatsappUrl = value
        case .threads: businessCard.threadsUrl = value
        }
    }

    private func updateVisibleLinkTypes() {
        var updatedTypes = SocialLinkType.allCases.filter { linkType in
            getValue(for: linkType) != nil && !getValue(for: linkType)!.isEmpty
        }
        
        // Ensure LinkedIn and Twitter are always visible
        if !updatedTypes.contains(.linkedIn) {
            updatedTypes.insert(.linkedIn, at: 0)
        }
        if !updatedTypes.contains(.twitter) {
            updatedTypes.insert(.twitter, at: min(1, updatedTypes.count))
        }
        
        // Add newly selected links that don't have values yet
        for linkType in visibleLinkTypes {
            if !updatedTypes.contains(linkType) {
                updatedTypes.append(linkType)
            }
        }
        
        visibleLinkTypes = updatedTypes
    }

    private func updateOffsets() {
        offsets = Array(repeating: 0, count: visibleLinkTypes.count)
    }
}

struct SocialLinkRow: View {
    let linkType: SocialLinkType
    @Binding var value: String

    var body: some View {
        HStack {
            Image(linkType.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            TextField(linkType.displayName, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}
