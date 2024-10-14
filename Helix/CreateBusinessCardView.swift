//
//  CreateBusinessCardView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CreateBusinessCardView: View {
    @Binding var showCreateCard: Bool
    @State private var currentStep = 0
    @State private var businessCard = BusinessCard(
        // Initialize your businessCard properties here
    )
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showCancelConfirmation = false

    let steps = ["Basic Information", "Professional Information", "Description", "Contact Information", "Social Links", "Web Links", "Profile Image"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { showCancelConfirmation = true }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 20, weight: .medium))
                }
                Spacer()
                Text("Create Card")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: { saveBusinessCard() }) {
                    Text("Done")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
            
            // Progress bar
            CreateProgressBar(currentStep: currentStep)
                .padding()
            
            // Content wrapped in KeyboardAvoidingView
            KeyboardAvoidingView {
                ScrollView {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 0:
                            BasicInformationView(businessCard: $businessCard)
                        case 1:
                            ProfessionalInformationView(businessCard: $businessCard)
                        case 2:
                            DescriptionView(businessCard: $businessCard)
                        case 3:
                            ContactInformationView(businessCard: $businessCard)
                        case 4:
                            SocialLinksView(businessCard: $businessCard)
                        case 5:
                            WebLinksView(businessCard: $businessCard)
                        case 6:
                            ProfileImageView(businessCard: $businessCard)
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button(action: { currentStep -= 1 }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
                Spacer()
                if currentStep < steps.count - 1 {
                    Button(action: { currentStep += 1 }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(currentStep == 0 && businessCard.firstName.isEmpty ? Color.gray : AppColors.primary)
                    .cornerRadius(20)
                    .disabled(currentStep == 0 && businessCard.firstName.isEmpty)
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .edgesIgnoringSafeArea(.bottom)
        .confirmationDialog("Are you sure you want to cancel?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Cancel without saving", role: .destructive) {
                showCreateCard = false
            }
            Button("Continue editing", role: .cancel) {}
        } message: {
            Text("Your progress will be lost if you cancel now.")
        }
    }

    private func saveBusinessCard() {
        Task {
            do {
                guard let userId = authManager.currentUser?.uid else {
                    print("Error: No authenticated user found")
                    return
                }
                
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(userId)
                
                let document = try await userRef.getDocument()
                
                if let userData = document.data() {
                    let isPro = userData["isPro"] as? Bool ?? false
                    let username = userData["username"] as? String ?? ""
                    let primaryCardPlaceholder = userData["primaryCardPlaceholder"] as? Bool ?? true
                    
                    var cardData = self.businessCard
                    cardData.username = username
                    cardData.isPrimary = primaryCardPlaceholder
                    cardData.isActive = isPro || primaryCardPlaceholder
                    
                    if primaryCardPlaceholder {
                        cardData.cardSlug = username
                    } else {
                        cardData.cardSlug = try await generateUniqueSlug()
                    }
                    
                    cardData.createdAt = Date()
                    cardData.updatedAt = Date()
                    
                    let businessCardsRef = userRef.collection("businessCards")
                    
                    var cardDict = try cardData.asDictionary()
                    cardDict["createdAt"] = FieldValue.serverTimestamp()
                    cardDict["updatedAt"] = FieldValue.serverTimestamp()
                    
                    try await businessCardsRef.document(cardData.cardSlug).setData(cardDict)
                    
                    print("Business card successfully added!")
                    if primaryCardPlaceholder {
                        try await userRef.updateData([
                            "primaryCardId": cardData.cardSlug,
                            "primaryCardPlaceholder": false
                        ])
                    }
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    print("Error fetching user document")
                }
            } catch {
                print("Error saving business card: \(error.localizedDescription)")
            }
        }
    }

    private func generateUniqueSlug() async throws -> String {
        let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
        let blacklist = ["ass", "fuck", "shit", "dick", "cunt", "bitch"]
        let db = Firestore.firestore()
        let maxAttempts = 10
        
        for _ in 0..<maxAttempts {
            let slug = String((0..<3).map { _ in characters.randomElement()! })
            
            if !blacklist.contains(slug) {
                let query = db.collection("users").document(authManager.currentUser!.uid)
                    .collection("businessCards")
                    .whereField("cardSlug", isEqualTo: slug)
                
                let snapshot = try await query.getDocuments()
                
                if snapshot.documents.isEmpty {
                    return slug
                }
            }
        }
        
        throw NSError(domain: "com.helix.error", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to generate a unique slug after \(maxAttempts) attempts"])
    }
}
