//
//  SocialLinkType.swift
//  Helix
//
//  Created by Richard Waithe on 10/13/24.
//

enum SocialLinkType: String, CaseIterable {
    case linkedIn, twitter, facebook, instagram, tiktok, youtube, discord, twitch, snapchat, telegram, whatsapp, threads
    
    var displayName: String {
        switch self {
        case .linkedIn: return "LinkedIn"
        case .twitter: return "X/Twitter"
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
        return rawValue
    }
    
    var baseURL: String {
        switch self {
        case .linkedIn: return "https://www.linkedin.com/in/"
        case .twitter: return "https://twitter.com/"
        case .facebook: return "https://www.facebook.com/"
        case .instagram: return "https://www.instagram.com/"
        case .tiktok: return "https://www.tiktok.com/@"
        case .youtube: return "https://www.youtube.com/channel/"
        case .discord: return "https://discord.com/users/"
        case .twitch: return "https://www.twitch.tv/"
        case .snapchat: return "https://www.snapchat.com/add/"
        case .telegram: return "https://t.me/"
        case .whatsapp: return "https://wa.me/"
        case .threads: return "https://www.threads.net/@"
        }
    }
}
