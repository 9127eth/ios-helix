//
//  TagManager.swift.swift
//  Helix
//
//  Created by Richard Waithe on 11/30/24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class TagManager: ObservableObject {
    @Published var availableTags: [Tag] = []
    @Published var lastUsedTagId: String?
    private let db = Firestore.firestore()
    
    init() {
        fetchTags()
    }
    
    func fetchTags() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("tags")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching tags: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.availableTags = documents.compactMap { document in
                    try? document.data(as: Tag.self)
                }
            }
    }
    
    func createTag(_ name: String) async throws -> Tag {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw TagError.userNotAuthenticated
        }
        
        // Check for existing tag
        let existingTag = availableTags.first { $0.name.lowercased() == name.lowercased() }
        if let existing = existingTag {
            return existing
        }
        
        // Create new tag
        let newTag = Tag(name: name, userId: userId, createdAt: Date())
        let docRef = try await db.collection("users").document(userId)
            .collection("tags")
            .addDocument(from: newTag)
        
        var savedTag = newTag
        savedTag.id = docRef.documentID
        
        // Update published property on main thread
        await MainActor.run {
            self.lastUsedTagId = docRef.documentID
        }
        
        return savedTag
    }
    
    func deleteTag(_ tagId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw TagError.userNotAuthenticated
        }
        
        // Delete tag document
        try await db.collection("users").document(userId)
            .collection("tags")
            .document(tagId)
            .delete()
            
        // Remove tag reference from all contacts
        let contactsRef = db.collection("users").document(userId).collection("contacts")
        let contacts = try await contactsRef.whereField("tags", arrayContains: tagId).getDocuments()
        
        for contact in contacts.documents {
            try await contact.reference.updateData([
                "tags": FieldValue.arrayRemove([tagId])
            ])
        }
    }
    
    enum TagError: Error {
        case userNotAuthenticated
        case tagCreationFailed
    }
}

