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
    
    static func uploadImage(_ imageData: Data) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
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
}