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
    @State private var currentStep = 0
    @State private var businessCard = BusinessCard(
        // Omit the `id` parameter
        cardSlug: "",
        userId: "",
        isPrimary: true,
        username: "",
        firstName: "",
        middleName: "",
        lastName: "",
        prefix: "",
        credentials: "",
        pronouns: "",
        description: "",
        jobTitle: "",
        company: "",
        phoneNumber: "",
        email: "",
        aboutMe: "",
        customMessage: "",
        customMessageHeader: "",
        linkedIn: "",
        twitter: "",
        facebookUrl: "",
        instagramUrl: "",
        tiktokUrl: "",
        youtubeUrl: "",
        discordUrl: "",
        twitchUrl: "",
        snapchatUrl: "",
        telegramUrl: "",
        whatsappUrl: "",
        threadsUrl: "",
        webLinks: [],
        cvUrl: "",
        cvHeader: "",
        cvDescription: "",
        cvDisplayText: "",
        imageUrl: "",
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        customSlug: "",
        isPro: false
    )
    
    let steps = ["Basic Information", "Contact Information", "Social Links", "Web Links", "Profile Image"]
    
    var body: some View {
        VStack {
            ProgressView(value: Double(currentStep), total: Double(steps.count))
                .padding()
            
            Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                .font(.headline)
                .padding()
            
            ScrollView {
                VStack {
                    switch currentStep {
                    case 0:
                        BasicInformationView(businessCard: $businessCard)
                    case 1:
                        ContactInformationView(businessCard: $businessCard)
                    case 2:
                        SocialLinksView(businessCard: $businessCard)
                    case 3:
                        WebLinksView(businessCard: $businessCard)
                    case 4:
                        ProfileImageView(businessCard: $businessCard)
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
            
            HStack {
                if currentStep > 0 {
                    Button("Previous") {
                        currentStep -= 1
                    }
                }
                
                Spacer()
                
                Button(currentStep == steps.count - 1 ? "Finish" : "Next") {
                    if currentStep < steps.count - 1 {
                        currentStep += 1
                    } else {
                        saveBusinessCard()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Create Your Business Card")
    }
    
    private func saveBusinessCard() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        let db = Firestore.firestore()
        let cardRef = db.collection("users").document(userId).collection("businessCards").document()
        
        businessCard.id = cardRef.documentID
        businessCard.cardSlug = cardRef.documentID
        businessCard.userId = userId
        businessCard.isPrimary = true
        businessCard.isActive = true
        businessCard.createdAt = Date()
        businessCard.updatedAt = Date()
        
        do {
            try cardRef.setData(from: businessCard)
            print("Business card created successfully")
            // Navigate back to the main view or show a success message
        } catch let error {
            print("Error saving business card: \(error)")
            // Show an error message to the user
        }
    }
}
