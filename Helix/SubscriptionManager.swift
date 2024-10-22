//
//  SubscriptionManager.swift
//  Helix
//
//  Created by Richard Waithe on 10/18/24.
//

import StoreKit
import FirebaseFirestore
import FirebaseAuth

class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    private var productIds = ["001", "002"] // Updated product IDs
    
    init() {
        Task {
            await loadProducts()
            await updatePurchasedSubscriptions()
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIds)
            products = storeProducts
            print("Loaded products: \(products.map { $0.id })")
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func updatePurchasedSubscriptions() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if let product = products.first(where: { $0.id == transaction.productID }) {
                purchasedSubscriptions.append(product)
            }
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            guard case .verified(let transaction) = verificationResult else {
                throw SubscriptionError.failedVerification
            }
            await transaction.finish()
            await updatePurchasedSubscriptions()
            await updateFirebaseProStatus(true)
        case .userCancelled:
            throw SubscriptionError.userCancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    func updateFirebaseProStatus(_ isPro: Bool) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            return
        }
        
        let db = Firestore.firestore()
        do {
            // Start a batch write
            let batch = db.batch()
            
            // 1. Update user's pro status
            let userRef = db.collection("users").document(userId)
            batch.updateData(["isPro": isPro], forDocument: userRef)
            
            // 2. Get all user's business cards
            let cardsSnapshot = try await userRef.collection("businessCards").getDocuments()
            
            // 3. Update each card
            for cardDoc in cardsSnapshot.documents {
                let cardRef = cardDoc.reference
                let isPrimary = cardDoc.data()["isPrimary"] as? Bool ?? false
                
                // Update both isPro and isActive status
                var updateData: [String: Any] = ["isPro": isPro]
                
                // Only update isActive for non-primary cards
                if !isPrimary {
                    updateData["isActive"] = isPro
                }
                
                batch.updateData(updateData, forDocument: cardRef)
            }
            
            // 4. Commit all changes atomically
            try await batch.commit()
            print("Successfully updated user and cards pro status")
        } catch {
            print("Error updating pro status and cards: \(error)")
        }
    }
    
    @MainActor
    func restorePurchases() async throws {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if let product = products.first(where: { $0.id == transaction.productID }) {
                purchasedSubscriptions.append(product)
            }
        }
        
        // Update Firebase status
        if !purchasedSubscriptions.isEmpty {
            await updateFirebaseProStatus(true)
        }
    }
}

enum SubscriptionError: Error {
    case failedVerification
    case userCancelled
    case pending
    case unknown
}
