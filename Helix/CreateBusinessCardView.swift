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
        guard let userId = authManager.currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let userData = document.data()
                let isPro = userData?["isPro"] as? Bool ?? false
                let username = userData?["username"] as? String ?? ""
                let primaryCardPlaceholder = userData?["primaryCardPlaceholder"] as? Bool ?? true
                
                var cardData = self.businessCard
                cardData.username = username
                cardData.isPrimary = primaryCardPlaceholder
                cardData.isActive = isPro || primaryCardPlaceholder
                cardData.cardSlug = primaryCardPlaceholder ? username : UUID().uuidString
                cardData.createdAt = Date()
                cardData.updatedAt = Date()
                
                let businessCardsRef = userRef.collection("businessCards")
                
                do {
                    var cardDict = try cardData.asDictionary()
                    cardDict["createdAt"] = FieldValue.serverTimestamp()
                    cardDict["updatedAt"] = FieldValue.serverTimestamp()
                    
                    businessCardsRef.document(cardData.cardSlug).setData(cardDict) { error in
                        if let error = error {
                            print("Error adding document: \(error)")
                        } else {
                            print("Business card successfully added!")
                            if primaryCardPlaceholder {
                                userRef.updateData([
                                    "primaryCardId": cardData.cardSlug,
                                    "primaryCardPlaceholder": false
                                ])
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                } catch {
                    print("Error converting business card to dictionary: \(error)")
                }
            } else {
                print("Error fetching user document: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
