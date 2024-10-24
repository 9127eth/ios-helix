//
//  CreateBusinessCardView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct CreateBusinessCardView: View {
    @Binding var showCreateCard: Bool
    @State private var currentStep = 0
    @State private var businessCard = BusinessCard(cardSlug: "", firstName: "")
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showCancelConfirmation = false
    @State private var showFirstNameError = false
    @State private var showDescriptionError = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedDocument: URL?
    @State private var isPro: Bool = false  // Add this line
    @State private var isAboutMeExpanded = false
    @State private var isAddDocumentExpanded = false

    let steps = ["Basic Information", "Professional Information", "Description", "Contact Information", "Social Links", "Web Links", "Profile Image"]

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack {
                Button(action: { showCancelConfirmation = true }) {
                    Text("Cancel")
                        .foregroundColor(Color.blue)
                }
                Spacer()
                Text("Create Card")
                    .font(.headline)
                    .foregroundColor(AppColors.bodyPrimaryText)
                Spacer()
                if currentStep < steps.count - 1 {
                    Button(action: handleNextButton) {
                        Text("Next")
                            .foregroundColor(Color.blue)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .padding()
            .background(AppColors.barMenuBackground)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
            
            // Progress bar
            CreateProgressBar(currentStep: currentStep)
                .padding()
            
            // Content wrapped in KeyboardAvoidingView
            ScrollView {
                VStack(spacing: 20) {
                    switch currentStep {
                    case 0:
                        BasicInformationView(businessCard: $businessCard, showFirstNameError: $showFirstNameError)
                    case 1:
                        ProfessionalInformationView(businessCard: $businessCard)
                    case 2:
                        DescriptionView(businessCard: $businessCard, showDescriptionError: $showDescriptionError)
                    case 3:
                        ContactInformationView(businessCard: $businessCard)
                    case 4:
                        SocialLinksView(businessCard: $businessCard, showHeader: true)
                    case 5:
                        WebLinksView(businessCard: $businessCard)
                    case 6:
                        ProfileImageView(businessCard: $businessCard)
                        
                        // About Me Section
                        DisclosureGroup(isExpanded: $isAboutMeExpanded) {
                            VStack(alignment: .leading, spacing: 8) {
                                TextEditor(text: Binding(
                                    get: { businessCard.aboutMe ?? "" },
                                    set: { businessCard.aboutMe = $0.isEmpty ? nil : $0 }
                                ))
                                .frame(height: 100)
                                .padding(8)
                                .background(AppColors.textFieldBackground) // Changed this line
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.bottom, 16)
                                

                            }
                            .padding(.top, 8)
                        } label: {
                            Text("About Me")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Add Document Section
                        DisclosureGroup(isExpanded: $isAddDocumentExpanded) {
                            DocumentView(
                                businessCard: $businessCard,
                                showHeader: false,
                                isPro: $isPro,
                                selectedDocument: $selectedDocument
                            )
                        } label: {
                            Text("Add Document")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    case 7:
                        DocumentView(
                            businessCard: $businessCard,
                            showHeader: false,
                            isPro: $isPro,
                            selectedDocument: $selectedDocument // Pass the binding
                        )
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
            
            // Navigation buttons
            VStack {
                Spacer() // This pushes the content to the bottom
                HStack {
                    if currentStep > 0 {
                        Button(action: { currentStep -= 1 }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .foregroundColor(AppColors.bodyPrimaryText)
                        }
                    }
                    Spacer()
                    Button(action: saveBusinessCard) {
                        Text("Done")
                            .foregroundColor(AppColors.buttonText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.buttonBackground)
                    .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20) // Add more bottom padding
            }
            .padding(.bottom, 30) // Add extra bottom padding to lift from screen edge
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .dismissKeyboardOnTap()
        .onAppear {
            fetchUserProStatus()
        }
    }

    private func saveBusinessCard() {
        let missingFields = validateRequiredFields()
        if !missingFields.isEmpty {
            showAlert = true
            alertMessage = "Please fill out the following required field(s): \(missingFields.joined(separator: ", "))"
            return
        }

        Task {
            do {
                // Upload the document if one is selected
                if let documentURL = selectedDocument {
                    try await uploadDocument(documentURL)
                }

                guard let userId = authManager.currentUser?.uid else {
                    print("Error: No authenticated user found")
                    return
                }
                
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(userId)
                
                // Force fetch the latest user data from the server
                let document = try await userRef.getDocument(source: .server)
                
                if let userData = document.data() {
                    let isPro = userData["isPro"] as? Bool ?? false
                    let username = userData["username"] as? String ?? ""
                    let primaryCardPlaceholder = userData["primaryCardPlaceholder"] as? Bool ?? true
                    
                    var cardData = self.businessCard
                    cardData.isPrimary = primaryCardPlaceholder
                    cardData.isActive = isPro || primaryCardPlaceholder
                    cardData.isPro = isPro  // Add this line
                    
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
                showAlert = true
                alertMessage = "Error saving business card: \(error.localizedDescription)"
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

    private func handleNextButton() {
        switch currentStep {
        case 0:
            if businessCard.firstName.isEmpty {
                showFirstNameError = true
            } else {
                currentStep += 1
                showFirstNameError = false
            }
        case 2:
            if businessCard.description.isEmpty {
                showDescriptionError = true
            } else {
                currentStep += 1
                showDescriptionError = false
            }
        default:
            currentStep += 1
        }
    }

    private func validateRequiredFields() -> [String] {
        var missingFields: [String] = []
        if businessCard.firstName.isEmpty {
            missingFields.append("First Name")
        }
        if businessCard.description.isEmpty {
            missingFields.append("Card Label")
        }
        return missingFields
    }

    private func uploadDocument(_ file: URL) async throws {
        // Implement the upload logic here, similar to how it was in DocumentView

        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "User not authenticated", code: -1, userInfo: nil)
        }

        // Start accessing the security-scoped resource
        guard file.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "Unable to access the selected file.", code: -1, userInfo: nil)
        }
        defer {
            file.stopAccessingSecurityScopedResource()
        }

        // Use NSFileCoordinator to coordinate access to the file
        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?

        coordinator.coordinate(readingItemAt: file, options: [], error: &coordinatorError) { (url) in
            do {
                // Check if the file is reachable
                guard (try? url.checkResourceIsReachable()) == true else {
                    throw NSError(domain: "Selected file is not reachable.", code: -1, userInfo: nil)
                }

                // Read the file data
                let data = try Data(contentsOf: url)

                // Proceed to upload the data to Firebase Storage
                let storage = Storage.storage()
                let storageRef = storage.reference()
                // Use the original filename instead of generating a UUID
                let originalFilename = url.lastPathComponent
                let documentRef = storageRef.child("docs/\(userId)/\(originalFilename)")

                let metadata = StorageMetadata()
                metadata.contentType = "application/pdf"
                // Store the original filename in metadata
                metadata.customMetadata = ["originalFilename": originalFilename]

                let uploadTask = documentRef.putData(data, metadata: metadata) { metadata, error in
                    if let error = error {
                        print("Error uploading document: \(error.localizedDescription)")
                        return
                    }

                    documentRef.downloadURL { url, error in
                        if let error = error {
                            print("Error getting download URL: \(error.localizedDescription)")
                            return
                        }

                        if let downloadURL = url {
                            DispatchQueue.main.async {
                                businessCard.cvUrl = downloadURL.absoluteString
                            }
                            print("Document uploaded successfully. URL: \(downloadURL.absoluteString)")
                        }
                    }
                }

                // Wait for the upload task to complete
                uploadTask.observe(.success) { snapshot in
                    print("Upload completed successfully")
                }

                // Handle progress or other states if needed

            } catch {
                print("Error reading file data: \(error.localizedDescription)")
            }
        }

        if let error = coordinatorError {
            throw error
        }
    }

    private func fetchUserProStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                self.isPro = document.data()?["isPro"] as? Bool ?? false
            } else {
                print("Error fetching user document: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
