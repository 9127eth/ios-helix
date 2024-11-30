//
//  Contact.swift
//  Helix
//
//  Created by Richard Waithe on 11/30/24.
//

import Foundation
import FirebaseFirestore

struct Contact: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var phone: String?
    var position: String?
    var company: String?
    var address: String?
    var email: String?
    var note: String?
    var tags: [String]?
    var dateAdded: Date
    var dateModified: Date
    var contactSource: ContactSource
    var imageUrl: String?
    
    enum ContactSource: String, Codable {
        case manual
        case imported
        case scanned
    }
    
    init(name: String) {
        self.name = name
        self.dateAdded = Date()
        self.dateModified = Date()
        self.contactSource = .manual
    }
    
    func asDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Contact", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create dictionary"])
        }
        return dictionary
    }
}