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
        VStack(spacing: 20) {
            CustomTextField(title: "LinkedIn", text: Binding($businessCard.linkedIn) ?? Binding.constant(""))
            CustomTextField(title: "Twitter", text: Binding($businessCard.twitter) ?? Binding.constant(""))
            CustomTextField(title: "Facebook", text: Binding($businessCard.facebookUrl) ?? Binding.constant(""))
            CustomTextField(title: "Instagram", text: Binding($businessCard.instagramUrl) ?? Binding.constant(""))
            CustomTextField(title: "TikTok", text: Binding($businessCard.tiktokUrl) ?? Binding.constant(""))
            CustomTextField(title: "YouTube", text: Binding($businessCard.youtubeUrl) ?? Binding.constant(""))
            CustomTextField(title: "Discord", text: Binding($businessCard.discordUrl) ?? Binding.constant(""))
            CustomTextField(title: "Twitch", text: Binding($businessCard.twitchUrl) ?? Binding.constant(""))
            CustomTextField(title: "Snapchat", text: Binding($businessCard.snapchatUrl) ?? Binding.constant(""))
            CustomTextField(title: "Telegram", text: Binding($businessCard.telegramUrl) ?? Binding.constant(""))
            CustomTextField(title: "WhatsApp", text: Binding($businessCard.whatsappUrl) ?? Binding.constant(""))
            CustomTextField(title: "Threads", text: Binding($businessCard.threadsUrl) ?? Binding.constant(""))
        }
    }
}
