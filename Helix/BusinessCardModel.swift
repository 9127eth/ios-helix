//
//  BusinessCardModel.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct BusinessCard: Identifiable, Codable {
    @DocumentID var id: String?
    var cardSlug: String
    var isPrimary: Bool
    var firstName: String
    var middleName: String?
    var lastName: String?
    var prefix: String?
    var credentials: String?
    var pronouns: String?
    var description: String = "" // This is the card description
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
    var isActive: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var customSlug: String?
    var isPro: Bool?
    var socialLinks: [SocialLinkType: String] = [:]

    init(cardSlug: String, firstName: String) {
        self.cardSlug = cardSlug
        self.firstName = firstName
        self.isPrimary = false
        self.description = ""
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, cardSlug, isPrimary, firstName, middleName, lastName, prefix, credentials, pronouns, description, jobTitle, company, phoneNumber, email, aboutMe, customMessage, customMessageHeader, linkedIn, twitter, facebookUrl, instagramUrl, tiktokUrl, youtubeUrl, discordUrl, twitchUrl, snapchatUrl, telegramUrl, whatsappUrl, threadsUrl, webLinks, cvUrl, cvHeader, cvDescription, cvDisplayText, imageUrl, isActive, createdAt, updatedAt, customSlug, isPro
    }

    var name: String {
        let fullName = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        return fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func getCardURL(username: String) -> String {
        let baseURL = "https://www.helixcard.app/c"
        if isPrimary {
            return "\(baseURL)/\(username)"
        } else {
            return "\(baseURL)/\(username)/\(cardSlug)"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        cardSlug = try container.decode(String.self, forKey: .cardSlug)
        isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        firstName = try container.decode(String.self, forKey: .firstName)
        middleName = try container.decodeIfPresent(String.self, forKey: .middleName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        prefix = try container.decodeIfPresent(String.self, forKey: .prefix)
        credentials = try container.decodeIfPresent(String.self, forKey: .credentials)
        pronouns = try container.decodeIfPresent(String.self, forKey: .pronouns)
        description = try container.decode(String.self, forKey: .description)
        jobTitle = try container.decodeIfPresent(String.self, forKey: .jobTitle)
        company = try container.decodeIfPresent(String.self, forKey: .company)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        aboutMe = try container.decodeIfPresent(String.self, forKey: .aboutMe)
        customMessage = try container.decodeIfPresent(String.self, forKey: .customMessage)
        customMessageHeader = try container.decodeIfPresent(String.self, forKey: .customMessageHeader)
        linkedIn = try container.decodeIfPresent(String.self, forKey: .linkedIn)
        twitter = try container.decodeIfPresent(String.self, forKey: .twitter)
        facebookUrl = try container.decodeIfPresent(String.self, forKey: .facebookUrl)
        instagramUrl = try container.decodeIfPresent(String.self, forKey: .instagramUrl)
        tiktokUrl = try container.decodeIfPresent(String.self, forKey: .tiktokUrl)
        youtubeUrl = try container.decodeIfPresent(String.self, forKey: .youtubeUrl)
        discordUrl = try container.decodeIfPresent(String.self, forKey: .discordUrl)
        twitchUrl = try container.decodeIfPresent(String.self, forKey: .twitchUrl)
        snapchatUrl = try container.decodeIfPresent(String.self, forKey: .snapchatUrl)
        telegramUrl = try container.decodeIfPresent(String.self, forKey: .telegramUrl)
        whatsappUrl = try container.decodeIfPresent(String.self, forKey: .whatsappUrl)
        threadsUrl = try container.decodeIfPresent(String.self, forKey: .threadsUrl)
        webLinks = try container.decodeIfPresent([WebLink].self, forKey: .webLinks)
        cvUrl = try container.decodeIfPresent(String.self, forKey: .cvUrl)
        cvHeader = try container.decodeIfPresent(String.self, forKey: .cvHeader)
        cvDescription = try container.decodeIfPresent(String.self, forKey: .cvDescription)
        cvDisplayText = try container.decodeIfPresent(String.self, forKey: .cvDisplayText)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        customSlug = try container.decodeIfPresent(String.self, forKey: .customSlug)
        isPro = try container.decodeIfPresent(Bool.self, forKey: .isPro)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(cardSlug, forKey: .cardSlug)
        try container.encode(isPrimary, forKey: .isPrimary)
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
        guard let id = self.id else {
            throw NSError(domain: "com.yourapp.error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid card ID"])
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.yourapp.error", code: 1002, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        let db = Firestore.firestore()
        let cardRef = db.collection("users").document(currentUser.uid).collection("businessCards").document(id)
        
        do {
            try await cardRef.setData(self.asDictionary(), merge: true)
            print("Successfully saved changes for card: \(id)")
        } catch {
            print("Error saving changes: \(error.localizedDescription)")
            throw error
        }
    }

    static func saveChanges(_ card: BusinessCard) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.yourapp.error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        guard let id = card.id else {
            throw NSError(domain: "com.yourapp.error", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Invalid card ID"])
        }
        
        let db = Firestore.firestore()
        let cardRef = db.collection("users").document(currentUser.uid).collection("businessCards").document(id)
        
        do {
            try await cardRef.setData(card.asDictionary(), merge: true)
            print("Successfully saved changes for card: \(id)")
        } catch {
            print("Error saving changes: \(error.localizedDescription)")
            throw error
        }
    }

    static func delete(_ card: BusinessCard) async throws {
        guard let currentUser = Auth.auth().currentUser, let cardId = card.id else {
            throw NSError(domain: "com.yourapp.error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found or invalid card ID"])
        }
        
        let db = Firestore.firestore()
        let cardRef = db.collection("users").document(currentUser.uid).collection("businessCards").document(cardId)
        
        do {
            try await cardRef.delete()
            print("Successfully deleted card: \(cardId)")
        } catch {
            print("Error deleting card: \(error.localizedDescription)")
            throw error
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
