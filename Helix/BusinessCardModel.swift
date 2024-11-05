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
    var description: String = ""
    var jobTitle: String?
    var company: String?
    var phoneNumber: String?
    var email: String?
    var aboutMe: String?
    var customMessage: String?
    var customMessageHeader: String?
    var cvUrl: String?
    var cvHeader: String?
    var cvDescription: String?
    var cvDisplayText: String?
    var imageUrl: String?
    var isActive: Bool = true
    var createdAt: Date
    var updatedAt: Date
    var customSlug: String?
    var isPro: Bool?
    
    // Social media link fields
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
    var cardDepthColor: String?  // Store hex color string
    
    init(cardSlug: String, firstName: String) {
        self.cardSlug = cardSlug
        self.firstName = firstName
        self.isPrimary = false
        self.description = ""
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
        // Remove the line initializing socialLinks
        // self.socialLinks = [:]
    }

    enum CodingKeys: String, CodingKey {
        case id, cardSlug, isPrimary, firstName, middleName, lastName, prefix, credentials, pronouns, description, jobTitle, company, phoneNumber, email, aboutMe, customMessage, customMessageHeader, cvUrl, cvHeader, cvDescription, cvDisplayText, imageUrl, isActive, createdAt, updatedAt, customSlug, isPro, linkedIn, twitter, facebookUrl, instagramUrl, tiktokUrl, youtubeUrl, discordUrl, twitchUrl, snapchatUrl, telegramUrl, whatsappUrl, threadsUrl, webLinks
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
        cvUrl = try container.decodeIfPresent(String.self, forKey: .cvUrl)
        cvHeader = try container.decodeIfPresent(String.self, forKey: .cvHeader)
        cvDescription = try container.decodeIfPresent(String.self, forKey: .cvDescription)
        cvDisplayText = try container.decodeIfPresent(String.self, forKey: .cvDisplayText)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        customSlug = try container.decodeIfPresent(String.self, forKey: .customSlug)
        isPro = try container.decodeIfPresent(Bool.self, forKey: .isPro)
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

        // Handle Timestamp, Date, Double, and Int values for createdAt
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else if let timestampDouble = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestampDouble)
        } else if let timestampInt = try? container.decode(Int.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: Double(timestampInt))
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format for createdAt")
        }

        // Handle Timestamp, Date, Double, and Int values for updatedAt
        if let timestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: .updatedAt) {
            updatedAt = date
        } else if let timestampDouble = try? container.decode(Double.self, forKey: .updatedAt) {
            updatedAt = Date(timeIntervalSince1970: timestampDouble)
        } else if let timestampInt = try? container.decode(Int.self, forKey: .updatedAt) {
            updatedAt = Date(timeIntervalSince1970: Double(timestampInt))
        } else {
            throw DecodingError.dataCorruptedError(forKey: .updatedAt, in: container, debugDescription: "Invalid date format for updatedAt")
        }
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
        try container.encodeIfPresent(cvUrl, forKey: .cvUrl)
        try container.encodeIfPresent(cvHeader, forKey: .cvHeader)
        try container.encodeIfPresent(cvDescription, forKey: .cvDescription)
        try container.encodeIfPresent(cvDisplayText, forKey: .cvDisplayText)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(customSlug, forKey: .customSlug)
        try container.encodeIfPresent(isPro, forKey: .isPro)
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
        
        // Encode createdAt and updatedAt as Firestore Timestamps
        let timestampCreatedAt = Timestamp(date: createdAt)
        try container.encode(timestampCreatedAt, forKey: .createdAt)
        
        let timestampUpdatedAt = Timestamp(date: updatedAt)
        try container.encode(timestampUpdatedAt, forKey: .updatedAt)
    }

    mutating func updateSocialLink(type: SocialLinkType, value: String) {
        switch type {
        case .linkedIn: linkedIn = value
        case .twitter: twitter = value
        case .facebook: facebookUrl = value
        case .instagram: instagramUrl = value
        case .tiktok: tiktokUrl = value
        case .youtube: youtubeUrl = value
        case .discord: discordUrl = value
        case .twitch: twitchUrl = value
        case .snapchat: snapchatUrl = value
        case .telegram: telegramUrl = value
        case .whatsapp: whatsappUrl = value
        case .threads: threadsUrl = value
        }
    }

    mutating func removeSocialLink(_ type: SocialLinkType) {
        switch type {
        case .linkedIn: linkedIn = nil
        case .twitter: twitter = nil
        case .facebook: facebookUrl = nil
        case .instagram: instagramUrl = nil
        case .tiktok: tiktokUrl = nil
        case .youtube: youtubeUrl = nil
        case .discord: discordUrl = nil
        case .twitch: twitchUrl = nil
        case .snapchat: snapchatUrl = nil
        case .telegram: telegramUrl = nil
        case .whatsapp: whatsappUrl = nil
        case .threads: threadsUrl = nil
        }
    }

    func socialLinkValue(for type: SocialLinkType) -> String? {
        switch type {
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
        guard let userId = Auth.auth().currentUser?.uid,
              let id = card.id else {
            throw NSError(domain: "com.yourapp.error", code: 1001, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid user or card ID"])
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        // Get the current user's pro status
        let userDoc = try await userRef.getDocument()
        let isPro = userDoc.data()?["isPro"] as? Bool ?? false
        
        var updatedData = try card.asDictionary()
        
        // Update isPro and isActive status
        updatedData["isPro"] = isPro
        if !card.isPrimary {
            updatedData["isActive"] = isPro
        }
        
        // Handle social links
        for linkType in SocialLinkType.allCases {
            let key = linkType.rawValue + "Url"
            if card.socialLinkValue(for: linkType) == nil {
                updatedData[key] = FieldValue.delete()
            }
        }
        
        let cardRef = userRef.collection("businessCards").document(id)
        try await cardRef.setData(updatedData, merge: true)
    }

    static func delete(_ card: BusinessCard) async throws {
        guard let currentUser = Auth.auth().currentUser, let cardId = card.id else {
            throw NSError(domain: "com.yourapp.error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found or invalid card ID"])
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.uid)
        let cardRef = userRef.collection("businessCards").document(cardId)
        
        do {
            // Start a batch write
            let batch = db.batch()
            
            // Delete the card
            batch.deleteDocument(cardRef)
            
            // If the card being deleted is the primary card, update the user document
            if card.isPrimary {
                batch.updateData([
                    "primaryCardPlaceholder": true,
                    "primaryCardId": FieldValue.delete()
                ], forDocument: userRef)
            }
            
            // Commit the batch
            try await batch.commit()
            
            print("Successfully deleted card: \(cardId)")
        } catch {
            print("Error deleting card: \(error.localizedDescription)")
            throw error
        }
    }
}

struct WebLink: Identifiable, Codable, Equatable {
    var id = UUID()
    var url: String
    var displayText: String
    
    static func == (lhs: WebLink, rhs: WebLink) -> Bool {
        return lhs.id == rhs.id && lhs.url == rhs.url && lhs.displayText == rhs.displayText
    }
}

