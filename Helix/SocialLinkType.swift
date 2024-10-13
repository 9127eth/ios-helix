//
//  SocialLinkType.swift
//  Helix
//
//  Created by Richard Waithe on 10/13/24.
//

enum SocialLinkType: CaseIterable {
    case linkedIn, twitter, facebook, instagram, tiktok, youtube, discord, twitch, snapchat, telegram, whatsapp, threads

    var displayName: String {
        switch self {
        case .linkedIn: return "LinkedIn"
        case .twitter: return "Twitter"
        case .facebook: return "Facebook"
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .youtube: return "YouTube"
        case .discord: return "Discord"
        case .twitch: return "Twitch"
        case .snapchat: return "Snapchat"
        case .telegram: return "Telegram"
        case .whatsapp: return "WhatsApp"
        case .threads: return "Threads"
        }
    }

    var iconName: String {
        switch self {
        case .linkedIn: return "linkedin_icon"
        case .twitter: return "twitter_icon"
        case .facebook: return "facebook_icon"
        case .instagram: return "instagram_icon"
        case .tiktok: return "tiktok_icon"
        case .youtube: return "youtube_icon"
        case .discord: return "discord_icon"
        case .twitch: return "twitch_icon"
        case .snapchat: return "snapchat_icon"
        case .telegram: return "telegram_icon"
        case .whatsapp: return "whatsapp_icon"
        case .threads: return "threads_icon"
        }
    }
}
