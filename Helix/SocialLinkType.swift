//
//  SocialLinkType.swift
//  Helix
//
//  Created by Richard Waithe on 10/13/24.
//

enum SocialLinkType: String, CaseIterable {
    case linkedIn, twitter, facebook, instagram, tiktok, youtube, discord, twitch, snapchat, telegram, whatsapp, threads
    
    var allowsFullURL: Bool {
        switch self {
        case .youtube, .discord, .facebook: return true
        default: return false
        }
    }
    
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
        case .youtube: return "YouTube Link"
        case .discord: return "Discord Link"
        case .facebook: return "Facebook Link"
        case .linkedIn: return "username/handle"
        case .twitter: return "username/handle"
        case .instagram: return "username/handle"
        case .tiktok: return "username/handle"
        case .twitch: return "username/handle"
        case .snapchat: return "username/handle"
        case .telegram: return "username/handle"
        case .whatsapp: return "+1234567890"
        case .threads: return "username/handle"
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
        
        // Special handling for specific platforms
        switch self {
        case .snapchat: 
            return "https://www.snapchat.com/add/"
        case .linkedIn:
            cleanInput = cleanInput.replacingOccurrences(of: "in/", with: "")
        case .twitter:
            cleanInput = cleanInput.replacingOccurrences(of: "@", with: "")
        case .instagram:
            // First remove any URL components
            let patterns = [
                "https://www.instagram.com/",
                "http://www.instagram.com/",
                "https://instagram.com/",
                "http://instagram.com/",
                "www.instagram.com/",
                "instagram.com/",
                "https://www./",  // Remove any malformed URLs from previous processing
                "http://www./",
                "https:///"
            ]
            
            for pattern in patterns {
                cleanInput = cleanInput.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
            }
        default:
            break
        }

        if cleanInput.lowercased().contains(self.baseURL.lowercased()) {
            for path in pathsToRemove {
                if cleanInput.contains(path) {
                    cleanInput = cleanInput.replacingOccurrences(of: path, with: "")
                }
            }
            
            while cleanInput.hasSuffix("/") {
                cleanInput.removeLast()
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
        
        // Handle both channel names and IDs
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
        
        // For platforms that accept full URLs, return the formatted URL directly
        if allowsFullURL {
            return formattedHandle
        }
        
        // For other platforms, use existing logic
        switch self {
        case .whatsapp:
            return baseURL + formatPhoneNumber(formattedHandle)
        default:
            return baseURL + formattedHandle
        }
    }
    
    var baseURL: String {
        switch self {
        case .youtube, .discord, .facebook:
            return ""  // No base URL needed for full URL platforms
        case .linkedIn: return "https://www.linkedin.com/in/"
        case .twitter: return "https://x.com/"
        case .instagram: return "https://www.instagram.com/"
        case .tiktok: return "https://www.tiktok.com/@"
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
