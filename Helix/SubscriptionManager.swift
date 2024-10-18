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
    private var productIds = ["001", "002"]
    
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
            try await db.collection("users").document(userId).updateData(["isPro": isPro])
            print("Successfully updated user's pro status in Firebase")
        } catch {
            print("Error updating pro status in Firebase: \(error)")
        }
    }
}

enum SubscriptionError: Error {
    case failedVerification
    case userCancelled
    case pending
    case unknown
}
