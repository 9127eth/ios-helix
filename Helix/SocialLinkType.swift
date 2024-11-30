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
    
    var placeholder: String {
        switch self {
        case .linkedIn: return "johndoe"
        case .twitter: return "johndoe"
        case .facebook: return "johndoe"
        case .instagram: return "johndoe"
        case .tiktok: return "johndoe"
        case .youtube: return "Channel Name or ID"
        case .discord: return "johndoe#1234"
        case .twitch: return "johndoe"
        case .snapchat: return "johndoe"
        case .telegram: return "johndoe"
        case .whatsapp: return "+1234567890"
        case .threads: return "johndoe"
        }
    }
    
    func formatInput(_ input: String) -> String {
        var cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove @ symbol if present
        if cleanInput.hasPrefix("@") {
            cleanInput.removeFirst()
        }
        
        // Remove URL if user pastes full URL
        if cleanInput.lowercased().contains(baseURL.lowercased()) {
            cleanInput = cleanInput.replacingOccurrences(of: baseURL, with: "", options: .caseInsensitive)
            // Remove any trailing slashes
            while cleanInput.hasPrefix("/") {
                cleanInput.removeFirst()
            }
            while cleanInput.hasSuffix("/") {
                cleanInput.removeLast()
            }
        }
        
        return cleanInput
    }
    
    func getFullURL(_ handle: String) -> String {
        let formattedHandle = formatInput(handle)
        switch self {
        case .whatsapp:
            // Keep only numbers and plus sign
            let numbersOnly = formattedHandle.filter { $0.isNumber || $0 == "+" }
            return baseURL + numbersOnly
        case .youtube:
            // Handle both channel names and IDs
            if formattedHandle.hasPrefix("UC") && formattedHandle.count == 24 {
                return baseURL + formattedHandle
            } else {
                return "https://www.youtube.com/c/" + formattedHandle
            }
        default:
            return baseURL + formattedHandle
        }
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
    
    var iconName: String {
        return rawValue
    }
}
