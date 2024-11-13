//
//  Untitled.swift
//  Helix
//
//  Created by Richard Waithe on 10/10/24.
//

import UIKit
import FirebaseCore
import GoogleSignIn
import StoreKit
import FirebaseFirestore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        AppConfiguration.setupAll()
        
        // Set up transaction listener
        setupTransactionListener()
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    private func setupTransactionListener() {
        Task {
            for await result in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                // Handle the transaction
                await handleVerifiedTransaction(transaction)
                
                // Finish the transaction
                await transaction.finish()
            }
        }
    }
    
    private func handleVerifiedTransaction(_ transaction: StoreKit.Transaction) async {
        // Check if this is the lifetime purchase
        let isLifetimePurchase = transaction.productID == "003"
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found when handling transaction")
            return
        }
        
        let db = Firestore.firestore()
        do {
            let userRef = db.collection("users").document(userId)
            let batch = db.batch()
            
            // Update user document
            let updates: [String: Any] = [
                "isPro": true,
                "isLifetime": isLifetimePurchase
            ]
            batch.updateData(updates, forDocument: userRef)
            
            // Update all user's business cards
            let cardsSnapshot = try await userRef.collection("businessCards").getDocuments()
            for cardDoc in cardsSnapshot.documents {
                let cardRef = cardDoc.reference
                let isPrimary = cardDoc.data()["isPrimary"] as? Bool ?? false
                
                var updateData: [String: Any] = ["isPro": true]
                if !isPrimary {
                    updateData["isActive"] = true
                }
                
                batch.updateData(updateData, forDocument: cardRef)
            }
            
            try await batch.commit()
            print("Successfully updated user and cards pro status from transaction")
        } catch {
            print("Error updating pro status from transaction: \(error)")
        }
    }
}
