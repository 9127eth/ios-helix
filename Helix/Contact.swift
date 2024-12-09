//
//  Contact.swift
//  Helix
//
//  Created by Richard Waithe on 11/30/24.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct Contact: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var firstName: String?
    var lastName: String?
    var phone: String?
    var position: String?
    var company: String?
    var address: String?
    var email: String?
    var website: String?
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
    
    init(name: String, source: ContactSource = .manual) {
        self.name = name
        self.dateAdded = Date()
        self.dateModified = Date()
        self.contactSource = source
    }
    
    private func parseName() -> (firstName: String, lastName: String?) {
        let components = name.trimmingCharacters(in: .whitespacesAndNewlines)
                           .components(separatedBy: " ")
        let firstName = components.first ?? ""
        let lastName = components.count > 1 ? components.dropFirst().joined(separator: " ") : nil
        return (firstName, lastName)
    }
    
    func asDictionary() throws -> [String: Any] {
        let parsedName = parseName()
        var dictionary: [String: Any] = [
            "name": name,
            "firstName": parsedName.firstName,
            "dateAdded": dateAdded,
            "dateModified": dateModified,
            "contactSource": contactSource.rawValue
        ]
        
        if let lastName = parsedName.lastName {
            dictionary["lastName"] = lastName
        }
        
        if let id = id { dictionary["id"] = id }
        if let phone = phone { dictionary["phone"] = phone }
        if let position = position { dictionary["position"] = position }
        if let company = company { dictionary["company"] = company }
        if let address = address { dictionary["address"] = address }
        if let email = email { dictionary["email"] = email }
        if let website = website { dictionary["website"] = website }
        if let note = note { dictionary["note"] = note }
        if let tags = tags { dictionary["tags"] = tags }
        if let imageUrl = imageUrl { dictionary["imageUrl"] = imageUrl }
        
        return dictionary
    }
    
    static func uploadImage(_ imageData: Data) async throws -> String {
        print("Starting image upload")
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            throw NSError(domain: "Contact", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageName = UUID().uuidString + ".jpg"
        let imageRef = storageRef.child("contacts/\(userId)/\(imageName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await imageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    static func deleteImage(url: String) async throws {
        guard let imageUrl = URL(string: url) else { return }
        let components = imageUrl.pathComponents
        if let index = components.firstIndex(of: "contacts") {
            let path = components[index...].joined(separator: "/")
            let storageRef = Storage.storage().reference().child(path)
            try await storageRef.delete()
        }
    }
    
    static func delete(_ contact: Contact) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let contactId = contact.id else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete contact document
        let contactRef = db.collection("users").document(userId)
            .collection("contacts").document(contactId)
        batch.deleteDocument(contactRef)
        
        // Delete associated image if exists
        if let imageUrl = contact.imageUrl {
            try await deleteImage(url: imageUrl)
        }
        
        try await batch.commit()
    }
    
    static func bulkDelete(_ contactIds: Set<String>) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        for contactId in contactIds {
            let contactRef = db.collection("users").document(userId)
                .collection("contacts").document(contactId)
            batch.deleteDocument(contactRef)
        }
        
        try await batch.commit()
    }
    
    static func bulkUpdateTags(_ contactIds: Set<String>, addTags: Set<String>) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        for contactId in contactIds {
            let contactRef = db.collection("users").document(userId)
                .collection("contacts").document(contactId)
            batch.updateData([
                "tags": FieldValue.arrayUnion(Array(addTags))
            ], forDocument: contactRef)
        }
        
        try await batch.commit()
    }
}