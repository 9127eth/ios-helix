//
//  SocialLinksView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct SocialLinksView: View {
    @Binding var businessCard: BusinessCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("LinkedIn", text: Binding($businessCard.linkedIn) ?? Binding.constant(""))
            TextField("Twitter", text: Binding($businessCard.twitter) ?? Binding.constant(""))
            TextField("Facebook", text: Binding($businessCard.facebookUrl) ?? Binding.constant(""))
            TextField("Instagram", text: Binding($businessCard.instagramUrl) ?? Binding.constant(""))
            TextField("TikTok", text: Binding($businessCard.tiktokUrl) ?? Binding.constant(""))
            TextField("YouTube", text: Binding($businessCard.youtubeUrl) ?? Binding.constant(""))
            TextField("Discord", text: Binding($businessCard.discordUrl) ?? Binding.constant(""))
            TextField("Twitch", text: Binding($businessCard.twitchUrl) ?? Binding.constant(""))
            TextField("Snapchat", text: Binding($businessCard.snapchatUrl) ?? Binding.constant(""))
            TextField("Telegram", text: Binding($businessCard.telegramUrl) ?? Binding.constant(""))
            TextField("WhatsApp", text: Binding($businessCard.whatsappUrl) ?? Binding.constant(""))
            TextField("Threads", text: Binding($businessCard.threadsUrl) ?? Binding.constant(""))
        }
    }
}