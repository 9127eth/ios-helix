import Foundation
import FirebaseFirestore
import FirebaseAuth

struct Tag: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var userId: String
    var createdAt: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func fetchTags() async throws -> [Tag] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Tag", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let db = Firestore.firestore()
        let snapshot = try await db.collection("users").document(userId)
            .collection("tags")
            .order(by: "name")
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Tag.self) }
    }
    
    static func create(name: String) async throws -> Tag {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Tag", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Check for existing tag
        let db = Firestore.firestore()
        let existingTags = try await db.collection("users").document(userId)
            .collection("tags")
            .whereField("name", isEqualTo: name)
            .getDocuments()
        
        if let existingTag = existingTags.documents.first {
            return try existingTag.data(as: Tag.self)
        }
        
        // Create new tag
        let newTag = Tag(name: name, userId: userId, createdAt: Date())
        let docRef = try await db.collection("users").document(userId)
            .collection("tags")
            .addDocument(from: newTag)
        
        var savedTag = newTag
        savedTag.id = docRef.documentID
        return savedTag
    }
    
    static func delete(_ tagId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Tag", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let db = Firestore.firestore()
        try await db.collection("users").document(userId)
            .collection("tags")
            .document(tagId)
            .delete()
    }
} 