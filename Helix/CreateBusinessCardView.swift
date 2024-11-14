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
    @State private var isPro: Bool = false
    @State private var isAboutMeExpanded = false
    @State private var isAddDocumentExpanded = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isPhoneNumberValid = true
    @State private var showPhoneNumberError = false

    let steps = ["Card Label", "Basic Information", "Professional Information", "Contact Information", "Social Links", "Web Links", "Profile Image"]

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar modification
            HStack {
                if currentStep > 0 {
                    Button(action: { currentStep -= 1 }) {
                        Text("Previous")
                            .foregroundColor(Color.blue)
                    }
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
                } else {
                    Button(action: saveBusinessCard) {
                        Text("Finish")
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
                        VStack(spacing: 24) {
                            DescriptionView(
                                businessCard: $businessCard,
                                showDescriptionError: $showDescriptionError,
                                isCreating: true
                            )
                            
                            NextSectionIndicator(
                                currentStep: currentStep, 
                                steps: steps,
                                action: handleNextButton
                            )
                            
                            VStack(spacing: 12) {
                                SaveAndCloseButtonView(action: saveBusinessCard)
                                CancelButtonView(action: { showCancelConfirmation = true })
                            }
                            .padding(.top, 8)
                        }
                    case 1:
                        VStack(spacing: 24) {
                            BasicInformationView(
                                businessCard: $businessCard,
                                showFirstNameError: $showFirstNameError,
                                showAboutMe: false
                            )
                            
                            NextSectionIndicator(
                                currentStep: currentStep, 
                                steps: steps,
                                action: handleNextButton
                            )
                            
                            VStack(spacing: 12) {
                                SaveAndCloseButtonView(action: saveBusinessCard)
                                CancelButtonView(action: { showCancelConfirmation = true })
                            }
                            .padding(.top, 8)
                        }
                    case 2:
                        VStack(spacing: 24) {
                            ProfessionalInformationView(businessCard: $businessCard)
                            
                            NextSectionIndicator(
                                currentStep: currentStep, 
                                steps: steps,
                                action: handleNextButton
                            )
                            
                            VStack(spacing: 12) {
                                SaveAndCloseButtonView(action: saveBusinessCard)
                                CancelButtonView(action: { showCancelConfirmation = true })
                            }
                            .padding(.top, 8)
                        }
                    case 3:
                        VStack(spacing: 24) {
                            ContactInformationView(
                                businessCard: $businessCard,
                                showHeader: true,
                                isPhoneNumberValid: $isPhoneNumberValid
                            )
                            
                            NextSectionIndicator(
                                currentStep: currentStep, 
                                steps: steps,
                                action: handleNextButton
                            )
                            
                            VStack(spacing: 12) {
                                SaveAndCloseButtonView(action: saveBusinessCard)
                                CancelButtonView(action: { showCancelConfirmation = true })
                            }
                            .padding(.top, 8)
                        }
                    case 4:
                        VStack(spacing: 24) {
                            SocialLinksView(businessCard: $businessCard, showHeader: true)
                            
                            NextSectionIndicator(
                                currentStep: currentStep, 
                                steps: steps,
                                action: handleNextButton
                            )
                            
                            VStack(spacing: 12) {
                                SaveAndCloseButtonView(action: saveBusinessCard)
                                CancelButtonView(action: { showCancelConfirmation = true })
                            }
                            .padding(.top, 8)
                        }
                    case 5:
                        VStack(spacing: 24) {
                            WebLinksView(businessCard: $businessCard)
                            
                            NextSectionIndicator(
                                currentStep: currentStep, 
                                steps: steps,
                                action: handleNextButton
                            )
                            
                            VStack(spacing: 12) {
                                SaveAndCloseButtonView(action: saveBusinessCard)
                                CancelButtonView(action: { showCancelConfirmation = true })
                            }
                            .padding(.top, 8)
                        }
                    case 6:
                        VStack(spacing: 24) {
                            ProfileImageView(businessCard: $businessCard, isCreating: true)
                            
                            CardThemeView(businessCard: $businessCard)
                            
                            DisclosureGroup(isExpanded: $isAboutMeExpanded) {
                                VStack(alignment: .leading, spacing: 8) {
                                    TextEditor(text: Binding(
                                        get: { businessCard.aboutMe ?? "" },
                                        set: { businessCard.aboutMe = $0.isEmpty ? nil : $0 }
                                    ))
                                    .frame(height: 100)
                                    .padding(8)
                                    .scrollContentBackground(.hidden)
                                    .background(AppColors.inputFieldBackground)
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

                            VStack(spacing: 12) {
                                SaveAndCloseButtonView(action: saveBusinessCard)
                                CancelButtonView(action: { showCancelConfirmation = true })
                            }
                            .padding(.top, 8)
                        }
                    default:
                        EmptyView()
                    }
                }
                .padding()
                .padding(.bottom, keyboardHeight) // Only add padding when keyboard is shown
            }
        }
        .background(AppColors.background)
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .confirmationDialog("Are you sure you want to cancel?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Cancel without saving", role: .destructive) {
                showCreateCard = false
            }
            Button("Continue editing", role: .cancel) {}
        } message: {
            Text("Your progress will be lost if you cancel now.")
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Required Fields"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .dismissKeyboardOnTap()
        .onAppear {
            fetchUserProStatus()
        }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self.keyboardHeight = keyboardFrame.height
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.keyboardHeight = 0
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    private func saveBusinessCard() {
        let missingFields = validateRequiredFields()
        if !missingFields.isEmpty {
            showAlert = true
            alertMessage = "Please fill out the following required field(s): \(missingFields.joined(separator: ", "))"
            return
        }

        Task { @MainActor in
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
                    cardData.isPro = isPro
                    
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
                    
                    await MainActor.run {
                        businessCardsRef.document(cardData.cardSlug).setData(cardDict)
                    }
                    
                    print("Business card successfully added!")
                    if primaryCardPlaceholder {
                        await MainActor.run {
                            userRef.updateData([
                                "primaryCardId": cardData.cardSlug,
                                "primaryCardPlaceholder": false
                            ])
                        }
                    }
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    print("Error fetching user document")
                }
            } catch {
                await MainActor.run {
                    showAlert = true
                    alertMessage = "Error saving business card: \(error.localizedDescription)"
                }
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
            if businessCard.description.isEmpty {
                showDescriptionError = true
            } else {
                currentStep += 1
                showDescriptionError = false
            }
        case 1:
            if businessCard.firstName.isEmpty {
                showFirstNameError = true
            } else {
                currentStep += 1
                showFirstNameError = false
            }
        case 3: // Contact Information step
            var hasError = false
            
            if let phoneNumber = businessCard.phoneNumber, !phoneNumber.isEmpty && !isPhoneNumberValid {
                showPhoneNumberError = true
                showAlert = true
                alertMessage = "Please enter a valid phone number"
                hasError = true
            }
            
            if let email = businessCard.email, !email.isEmpty && !isValidEmail(email) {
                showAlert = true
                alertMessage = "Please enter a valid email address"
                hasError = true
            }
            
            if !hasError {
                currentStep += 1
                showPhoneNumberError = false
            }
        default:
            currentStep += 1
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func validateRequiredFields() -> [String] {
        var missingFields: [String] = []
        if businessCard.firstName.isEmpty {
            missingFields.append("First Name")
        }
        if businessCard.description.isEmpty {
            missingFields.append("Card Label")
        }
        if let phoneNumber = businessCard.phoneNumber, !phoneNumber.isEmpty {
            if !isPhoneNumberValid {
                missingFields.append("Valid Phone Number")
            }
        }
        if let email = businessCard.email, !email.isEmpty && !isValidEmail(email) {
            missingFields.append("Valid Email Address")
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

struct CancelButtonView: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Cancel")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

struct SaveAndCloseButtonView: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Save and close")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppColors.barMenuBackground)
                )
        }
        .padding(.horizontal)
    }
}

struct NextSectionIndicator: View {
    let currentStep: Int
    let steps: [String]
    let action: () -> Void
    
    var body: some View {
        if currentStep < steps.count - 1 {
            Button(action: action) {
                HStack {
                    Text("Next: \(steps[currentStep + 1])")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

