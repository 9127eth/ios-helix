//
//  BusinessCardModel.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI
import Foundation
import FirebaseFirestore

struct BusinessCard: Identifiable, Codable {
    @DocumentID var id: String?
    var cardSlug: String
    var userId: String?  // Make this optional
    var isPrimary: Bool
    var username: String?
    var firstName: String
    var middleName: String?
    var lastName: String?
    var prefix: String?
    var credentials: String?
    var pronouns: String?
    var description: String // This is the card description
    var jobTitle: String?
    var company: String?
    var phoneNumber: String?
    var email: String?
    var aboutMe: String?
    var customMessage: String?
    var customMessageHeader: String?
    var linkedIn: String?
    var twitter: String?
    var facebookUrl: String?
    var instagramUrl: String?
    var tiktokUrl: String?
    var youtubeUrl: String?
    var discordUrl: String?
    var twitchUrl: String?
    var snapchatUrl: String?
    var telegramUrl: String?
    var whatsappUrl: String?
    var threadsUrl: String?
    var webLinks: [WebLink]?
    var cvUrl: String?
    var cvHeader: String?
    var cvDescription: String?
    var cvDisplayText: String?
    var imageUrl: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var customSlug: String?
    var isPro: Bool?

    enum CodingKeys: String, CodingKey {
        case id, cardSlug, userId, isPrimary, username, firstName, middleName, lastName, prefix, credentials, pronouns, description, jobTitle, company, phoneNumber, email, aboutMe, customMessage, customMessageHeader, linkedIn, twitter, facebookUrl, instagramUrl, tiktokUrl, youtubeUrl, discordUrl, twitchUrl, snapchatUrl, telegramUrl, whatsappUrl, threadsUrl, webLinks, cvUrl, cvHeader, cvDescription, cvDisplayText, imageUrl, isActive, createdAt, updatedAt, customSlug, isPro
    }

    var name: String {
        let fullName = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        return fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func getCardURL() -> String {
        let baseURL = "https://www.helixcard.app/c"
        if isPrimary {
            return "\(baseURL)/\(username ?? "")"
        } else {
            return "\(baseURL)/\(username ?? "")/\(cardSlug)"
        }
    }
    
    init(
        id: String? = nil,
        cardSlug: String = UUID().uuidString,
        userId: String? = nil,
        isPrimary: Bool = true,
        username: String? = nil,
        firstName: String = "",
        middleName: String? = nil,
        lastName: String? = nil,
        prefix: String? = nil,
        credentials: String? = nil,
        pronouns: String? = nil,
        description: String = "",
        jobTitle: String? = nil,
        company: String? = nil,
        phoneNumber: String? = nil,
        email: String? = nil,
        aboutMe: String? = nil,
        customMessage: String? = nil,
        customMessageHeader: String? = nil,
        linkedIn: String? = nil,
        twitter: String? = nil,
        facebookUrl: String? = nil,
        instagramUrl: String? = nil,
        tiktokUrl: String? = nil,
        youtubeUrl: String? = nil,
        discordUrl: String? = nil,
        twitchUrl: String? = nil,
        snapchatUrl: String? = nil,
        telegramUrl: String? = nil,
        whatsappUrl: String? = nil,
        threadsUrl: String? = nil,
        webLinks: [WebLink]? = nil,
        cvUrl: String? = nil,
        cvHeader: String? = nil,
        cvDescription: String? = nil,
        cvDisplayText: String? = nil,
        imageUrl: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        customSlug: String? = nil,
        isPro: Bool? = false
    ) {
        self.id = id
        self.cardSlug = cardSlug
        self.userId = userId
        self.isPrimary = isPrimary
        self.username = username
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.prefix = prefix
        self.credentials = credentials
        self.pronouns = pronouns
        self.description = description
        self.jobTitle = jobTitle
        self.company = company
        self.phoneNumber = phoneNumber
        self.email = email
        self.aboutMe = aboutMe
        self.customMessage = customMessage
        self.customMessageHeader = customMessageHeader
        self.linkedIn = linkedIn
        self.twitter = twitter
        self.facebookUrl = facebookUrl
        self.instagramUrl = instagramUrl
        self.tiktokUrl = tiktokUrl
        self.youtubeUrl = youtubeUrl
        self.discordUrl = discordUrl
        self.twitchUrl = twitchUrl
        self.snapchatUrl = snapchatUrl
        self.telegramUrl = telegramUrl
        self.whatsappUrl = whatsappUrl
        self.threadsUrl = threadsUrl
        self.webLinks = webLinks
        self.cvUrl = cvUrl
        self.cvHeader = cvHeader
        self.cvDescription = cvDescription
        self.cvDisplayText = cvDisplayText
        self.imageUrl = imageUrl
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.customSlug = customSlug
        self.isPro = isPro
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(cardSlug, forKey: .cardSlug)
        try container.encode(userId, forKey: .userId)
        try container.encode(isPrimary, forKey: .isPrimary)
        try container.encode(username, forKey: .username)
        try container.encode(firstName, forKey: .firstName)
        try container.encodeIfPresent(middleName, forKey: .middleName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(prefix, forKey: .prefix)
        try container.encodeIfPresent(credentials, forKey: .credentials)
        try container.encodeIfPresent(pronouns, forKey: .pronouns)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(jobTitle, forKey: .jobTitle)
        try container.encodeIfPresent(company, forKey: .company)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(aboutMe, forKey: .aboutMe)
        try container.encodeIfPresent(customMessage, forKey: .customMessage)
        try container.encodeIfPresent(customMessageHeader, forKey: .customMessageHeader)
        try container.encodeIfPresent(linkedIn, forKey: .linkedIn)
        try container.encodeIfPresent(twitter, forKey: .twitter)
        try container.encodeIfPresent(facebookUrl, forKey: .facebookUrl)
        try container.encodeIfPresent(instagramUrl, forKey: .instagramUrl)
        try container.encodeIfPresent(tiktokUrl, forKey: .tiktokUrl)
        try container.encodeIfPresent(youtubeUrl, forKey: .youtubeUrl)
        try container.encodeIfPresent(discordUrl, forKey: .discordUrl)
        try container.encodeIfPresent(twitchUrl, forKey: .twitchUrl)
        try container.encodeIfPresent(snapchatUrl, forKey: .snapchatUrl)
        try container.encodeIfPresent(telegramUrl, forKey: .telegramUrl)
        try container.encodeIfPresent(whatsappUrl, forKey: .whatsappUrl)
        try container.encodeIfPresent(threadsUrl, forKey: .threadsUrl)
        try container.encodeIfPresent(webLinks, forKey: .webLinks)
        try container.encodeIfPresent(cvUrl, forKey: .cvUrl)
        try container.encodeIfPresent(cvHeader, forKey: .cvHeader)
        try container.encodeIfPresent(cvDescription, forKey: .cvDescription)
        try container.encodeIfPresent(cvDisplayText, forKey: .cvDisplayText)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(isPro ?? false, forKey: .isPro)
    }

    mutating func setSocialLinkValue(for linkType: SocialLinkType, value: String) {
        switch linkType {
        case .linkedIn: self.linkedIn = value
        case .twitter: self.twitter = value
        case .facebook: self.facebookUrl = value
        case .instagram: self.instagramUrl = value
        case .tiktok: self.tiktokUrl = value
        case .youtube: self.youtubeUrl = value
        case .discord: self.discordUrl = value
        case .twitch: self.twitchUrl = value
        case .snapchat: self.snapchatUrl = value
        case .telegram: self.telegramUrl = value
        case .whatsapp: self.whatsappUrl = value
        case .threads: self.threadsUrl = value
        }
    }

    mutating func removeSocialLink(_ linkType: SocialLinkType) {
        switch linkType {
        case .linkedIn: self.linkedIn = nil
        case .twitter: self.twitter = nil
        case .facebook: self.facebookUrl = nil
        case .instagram: self.instagramUrl = nil
        case .tiktok: self.tiktokUrl = nil
        case .youtube: self.youtubeUrl = nil
        case .discord: self.discordUrl = nil
        case .twitch: self.twitchUrl = nil
        case .snapchat: self.snapchatUrl = nil
        case .telegram: self.telegramUrl = nil
        case .whatsapp: self.whatsappUrl = nil
        case .threads: self.threadsUrl = nil
        }
    }

    mutating func updateSocialLink(type: SocialLinkType, value: String?) {
        switch type {
        case .linkedIn: self.linkedIn = value
        case .twitter: self.twitter = value
        case .facebook: self.facebookUrl = value
        case .instagram: self.instagramUrl = value
        case .tiktok: self.tiktokUrl = value
        case .youtube: self.youtubeUrl = value
        case .discord: self.discordUrl = value
        case .twitch: self.twitchUrl = value
        case .snapchat: self.snapchatUrl = value
        case .telegram: self.telegramUrl = value
        case .whatsapp: self.whatsappUrl = value
        case .threads: self.threadsUrl = value
        }
    }

    func socialLinkValue(for linkType: SocialLinkType) -> String? {
        switch linkType {
        case .linkedIn: return linkedIn
        case .twitter: return twitter
        case .facebook: return facebookUrl
        case .instagram: return instagramUrl
        case .tiktok: return tiktokUrl
        case .youtube: return youtubeUrl
        case .discord: return discordUrl
        case .twitch: return twitchUrl
        case .snapchat: return snapchatUrl
        case .telegram: return telegramUrl
        case .whatsapp: return whatsappUrl
        case .threads: return threadsUrl
        }
    }
}

struct WebLink: Identifiable, Codable, Equatable {
    let id = UUID()
    var url: String
    var displayText: String
    
    static func == (lhs: WebLink, rhs: WebLink) -> Bool {
        return lhs.id == rhs.id && lhs.url == rhs.url && lhs.displayText == rhs.displayText
    }
}
