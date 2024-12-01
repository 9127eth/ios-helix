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
        
        // Handle common URL variations
        let pathsToRemove = [
            "/home", "/profile", "/user", "/u/", 
            "profile.php?id=", "pages/", "channel/",
            "@", "/public/", "/feed/", "/posts/"
        ]
        
        for path in pathsToRemove {
            if cleanInput.contains(path) {
                cleanInput = cleanInput.replacingOccurrences(of: path, with: "")
            }
        }
        
        // Remove @ symbol if present
        if cleanInput.hasPrefix("@") {
            cleanInput.removeFirst()
        }
        
        // Handle various URL formats
        let knownDomains = [
            "linkedin.com", "x.com", "twitter.com", 
            "facebook.com", "instagram.com", "tiktok.com",
            "youtube.com", "discord.com", "twitch.tv",
            "snapchat.com", "t.me", "wa.me",
            "threads.net",
            "linkedin.cn", "x.jp", "facebook.de",
            "eu.linkedin.com", "uk.linkedin.com"
        ]
        
        for domain in knownDomains {
            // Remove any protocol and www
            let patterns = [
                "https://www.\(domain)/",
                "http://www.\(domain)/",
                "https://\(domain)/",
                "http://\(domain)/",
                "www.\(domain)/"
            ]
            
            for pattern in patterns {
                if cleanInput.lowercased().contains(pattern.lowercased()) {
                    cleanInput = cleanInput.replacingOccurrences(
                        of: pattern,
                        with: "",
                        options: .caseInsensitive
                    )
                }
            }
        }
        
        // Special handling for specific platforms
        switch self {
        case .linkedIn:
            cleanInput = cleanInput.replacingOccurrences(of: "in/", with: "")
        case .twitter:
            cleanInput = cleanInput.replacingOccurrences(of: "@", with: "")
        case .instagram:
            cleanInput = cleanInput.replacingOccurrences(of: "instagram.com", with: "")
        default:
            break
        }
        
        // Remove query parameters
        if let queryStart = cleanInput.firstIndex(of: "?") {
            cleanInput = String(cleanInput[..<queryStart])
        }
        
        // Remove hash fragments
        if let hashStart = cleanInput.firstIndex(of: "#") {
            cleanInput = String(cleanInput[..<hashStart])
        }
        
        return cleanInput
    }
    
    func formatPhoneNumber(_ input: String) -> String {
        // Remove all non-numeric characters except +
        var cleaned = input.filter { $0.isNumber || $0 == "+" }
        
        // Ensure only one + at the start
        if cleaned.contains("+") {
            cleaned = "+" + cleaned.filter { $0 != "+" }
        }
        
        // Handle country codes without +
        if !cleaned.hasPrefix("+") {
            // Common formats: 00XXX, 011XXX (US international prefix)
            if cleaned.hasPrefix("00") {
                cleaned = "+" + cleaned.dropFirst(2)
            } else if cleaned.hasPrefix("011") {
                cleaned = "+" + cleaned.dropFirst(3)
            }
        }
        
        return cleaned
    }
    
    func getFullURL(_ handle: String) -> String {
        let formattedHandle = formatInput(handle)
        
        switch self {
        case .whatsapp:
            return baseURL + formatPhoneNumber(formattedHandle)
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
        case .twitter: return "https://x.com/"
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
