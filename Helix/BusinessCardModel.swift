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
    var username: String
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
    var socialLinks: [SocialLinkType: String] = [:]

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
            return "\(baseURL)/\(username)"
        } else {
            return "\(baseURL)/\(username)/\(cardSlug)"
        }
    }
    
    init(
        id: String? = nil,
        cardSlug: String = UUID().uuidString,
        userId: String? = nil,
        isPrimary: Bool = false,
        username: String = "",
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

    mutating func updateSocialLink(type: SocialLinkType, value: String) {
        socialLinks[type] = value
    }

    mutating func removeSocialLink(_ type: SocialLinkType) {
        socialLinks.removeValue(forKey: type)
    }

    func socialLinkValue(for type: SocialLinkType) -> String? {
        return socialLinks[type]
    }

    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "BusinessCard", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }

    func saveChanges() async throws {
        guard let userId = self.userId, let id = self.id else {
            throw NSError(domain: "com.yourapp.error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid user or card ID"])
        }
        
        let db = Firestore.firestore()
        let cardRef = db.collection("users").document(userId).collection("businessCards").document(id)
        
        try await cardRef.setData(self.asDictionary(), merge: true)
    }

    static func saveChanges(_ card: BusinessCard) async throws {
        guard let userId = card.userId, let id = card.id else {
            throw NSError(domain: "com.yourapp.error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid user or card ID"])
        }
        
        let db = Firestore.firestore()
        let cardRef = db.collection("users").document(userId).collection("businessCards").document(id)
        
        try await cardRef.setData(card.asDictionary(), merge: true)
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
