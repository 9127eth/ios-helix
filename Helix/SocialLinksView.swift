//
//  SocialLinksView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SocialLinksView: View {
    @Binding var businessCard: BusinessCard
    @State private var showingAddLinkPopup = false
    @State private var visibleLinkTypes: [SocialLinkType] = []
    var showHeader: Bool
    @State private var offsets: [CGFloat] = []

    init(businessCard: Binding<BusinessCard>, showHeader: Bool) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Social Links")
                    .font(.headline)
                    .padding(.bottom, 8)
            }
            
            Text("Enter your username or handle for each platform")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 16)
            
            ForEach(visibleLinkTypes.indices, id: \.self) { index in
                let linkType = visibleLinkTypes[index]
                ZStack {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Spacer()
                            Button(action: {
                                removeLink(at: index)
                            }) {
                                Image("trashDelete")
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
                        updateOffsets()
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
        #if compiler(>=5.9)  // iOS 17+
        .onChange(of: visibleLinkTypes) { oldTypes, newTypes in
            updateOffsets()
        }
        #else
        .onChange(of: visibleLinkTypes) { _ in
            updateOffsets()
        }
        #endif
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
        case .bluesky: return businessCard.blueskyUrl
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
        case .bluesky: businessCard.blueskyUrl = value
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
        updateOffsets()
    }

    private func updateOffsets() {
        offsets = Array(repeating: 0, count: visibleLinkTypes.count)
    }

    private func removeLink(at index: Int) {
        let linkType = visibleLinkTypes[index]
        // Remove the link type from visibleLinkTypes and offsets
        visibleLinkTypes.remove(at: index)
        offsets.remove(at: index)
        // Update the businessCard by removing the corresponding social link
        businessCard.removeSocialLink(linkType)
        updateVisibleLinkTypes()
    }

    // This method is kept for API compatibility but is no longer called
    // automatically when values change. The parent EditBusinessCardView is responsible
    // for saving all changes at once.
    func saveChangesToFirebase() {
        guard let userId = Auth.auth().currentUser?.uid,
              let cardId = businessCard.id else {
            print("Error: Unable to save changes. User ID or Card ID is missing.")
            return
        }

        let db = Firestore.firestore()
        let cardRef = db.collection("users").document(userId).collection("businessCards").document(cardId)

        cardRef.updateData([
            "linkedIn": businessCard.linkedIn as Any,
            "twitter": businessCard.twitter as Any,
            "facebookUrl": businessCard.facebookUrl as Any,
            "instagramUrl": businessCard.instagramUrl as Any,
            "tiktokUrl": businessCard.tiktokUrl as Any,
            "youtubeUrl": businessCard.youtubeUrl as Any,
            "discordUrl": businessCard.discordUrl as Any,
            "twitchUrl": businessCard.twitchUrl as Any,
            "snapchatUrl": businessCard.snapchatUrl as Any,
            "telegramUrl": businessCard.telegramUrl as Any,
            "whatsappUrl": businessCard.whatsappUrl as Any,
            "threadsUrl": businessCard.threadsUrl as Any,
            "blueskyUrl": businessCard.blueskyUrl as Any
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
            }
        }
    }
}

struct SocialLinkRow: View {
    let linkType: SocialLinkType
    @Binding var value: String
    @Environment(\.colorScheme) var colorScheme
    @State private var handle: String = ""
    
    var body: some View {
        HStack {
            Image(linkType.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                TextField(linkType.placeholder, text: $handle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: handle) { oldValue, newValue in
                        value = linkType.getFullURL(newValue)
                    }
                
                if !handle.isEmpty {
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .onAppear {
                // Convert existing URL back to handle on appear
                if !value.isEmpty {
                    handle = linkType.formatInput(value)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}
