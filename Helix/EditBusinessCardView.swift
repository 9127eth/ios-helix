//
//  EditBusinessCardView.swift
//  Helix
//
//  Created by Richard Waithe on 10/14/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import NotificationCenter
import FirebaseStorage

struct EditBusinessCardView: View {
    @Binding var businessCard: BusinessCard
    let username: String
    @State private var editedCard: BusinessCard
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCancelConfirmation = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var expandedSections: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var showFirstNameError = false
    @State private var showDescriptionError = false
    @State private var isPro: Bool = false
    @State private var selectedDocument: URL?
    
    let sections = ["Card Label", "Basic Information", "Professional Information", "Contact Information", "Social Links", "Web Links", "Profile Image", "Custom Header/Message", "Document"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.editSheetBackground.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(sections, id: \.self) { section in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedSections.contains(section) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            expandedSections.insert(section)
                                        } else {
                                            expandedSections.remove(section)
                                        }
                                    }
                                )
                            ) {
                                sectionContent(for: section, card: $editedCard)
                                    .padding(.top, 16)
                            } label: {
                                Text(section)
                                    .font(.headline)
                                    .foregroundColor(AppColors.primaryText)
                            }
                        }
                        
                        Divider()
                            .background(Color.gray)
                            .padding(.vertical)
                        
                        dangerSection
                    }
                    .padding()
                    .dismissKeyboardOnTap()
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCancelConfirmation = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveChanges()
                    }) {
                        HStack {
                            Image("save")
                                .renderingMode(.template)
                            Text("Save")
                        }
                    }
                }
            }
        }
        .alert("Confirm Cancel", isPresented: $showingCancelConfirmation) {
            Button("Continue Editing", role: .cancel) {}
            Button("Yes, Cancel", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel? Any unsaved changes will be lost.")
        }
        .alert(isPresented: $showingSaveError) {
            Alert(
                title: Text("Error Saving Changes"),
                message: Text(saveErrorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Confirm Deletion", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteBusinessCard()
            }
        } message: {
            Text("Are you sure you want to delete this business card? This action is irreversible.")
        }
        .onAppear(perform: fetchUserProStatus)
    }
    
    func sectionContent(for section: String, card: Binding<BusinessCard>) -> some View {
        switch section {
        case "Card Label":
            return AnyView(DescriptionView(businessCard: card, showHeader: false, showDescriptionError: $showDescriptionError))
        case "Basic Information":
            return AnyView(BasicInformationView(businessCard: card, showHeader: false, showFirstNameError: $showFirstNameError))
        case "Professional Information":
            return AnyView(ProfessionalInformationView(businessCard: card, showHeader: false))
        case "Contact Information":
            return AnyView(ContactInformationView(businessCard: card, showHeader: false))
        case "Social Links":
            return AnyView(SocialLinksView(businessCard: card, showHeader: false))
        case "Web Links":
            return AnyView(WebLinksView(businessCard: card, showHeader: false))
        case "Profile Image":
            return AnyView(ProfileImageView(businessCard: card, showHeader: false, isCreating: false))
        case "Custom Header/Message":
            return AnyView(CustomSectionView(businessCard: card, showHeader: false))
        case "Document":
            return AnyView(DocumentView(
                businessCard: card,
                showHeader: false,
                isPro: $isPro,
                selectedDocument: $selectedDocument
            ))
        default:
            return AnyView(EmptyView())
        }
    }
    
    private func saveChanges() {
        showFirstNameError = editedCard.firstName.isEmpty
        showDescriptionError = editedCard.description.isEmpty

        var missingFields: [String] = []
        if showFirstNameError {
            missingFields.append("First Name")
        }
        if showDescriptionError {
            missingFields.append("Card Label")
        }

        if !missingFields.isEmpty {
            let fieldList = missingFields.joined(separator: " and ")
            saveErrorMessage = "Please fill out the following required field\(missingFields.count > 1 ? "s" : ""): \(fieldList)."
            showingSaveError = true
            return
        }

        Task { @MainActor in
            do {
                // If the document URL was cleared, delete the old document
                if businessCard.cvUrl != nil && editedCard.cvUrl == nil {
                    try await deleteDocumentIfNeeded()
                    
                    // Update Firestore document to remove CV-related fields
                    guard let userId = Auth.auth().currentUser?.uid,
                          let cardId = editedCard.id else { return }
                    
                    let db = Firestore.firestore()
                    let cardRef = db.collection("users").document(userId)
                        .collection("businessCards").document(cardId)
                    
                    await MainActor.run {
                        cardRef.updateData([
                            "cvUrl": FieldValue.delete(),
                            "cvHeader": FieldValue.delete(),
                            "cvDescription": FieldValue.delete(),
                            "cvDisplayText": FieldValue.delete()
                        ])
                    }
                }

                // If a new document is selected, upload it
                if let documentURL = selectedDocument {
                    let downloadURLString = try await uploadDocument(documentURL)
                    editedCard.cvUrl = downloadURLString
                }

                // Handle social links
                for linkType in SocialLinkType.allCases {
                    if editedCard.socialLinkValue(for: linkType) == nil {
                        editedCard.removeSocialLink(linkType)
                    }
                }

                try await BusinessCard.saveChanges(editedCard)
                businessCard = editedCard // Update the original card
                presentationMode.wrappedValue.dismiss()
            } catch {
                await MainActor.run {
                    saveErrorMessage = error.localizedDescription
                    showingSaveError = true
                }
            }
        }
    }
    
    private func uploadDocument(_ file: URL) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "User not authenticated", code: -1, userInfo: nil)
        }

        guard file.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "Unable to access the selected file.", code: -1, userInfo: nil)
        }
        defer {
            file.stopAccessingSecurityScopedResource()
        }

        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?
        var fileData: Data?
        var localError: Error?

        coordinator.coordinate(readingItemAt: file, options: [], error: &coordinatorError) { url in
            do {
                guard (try? url.checkResourceIsReachable()) == true else {
                    localError = NSError(domain: "Selected file is not reachable.", code: -1, userInfo: nil)
                    return
                }
                fileData = try Data(contentsOf: url)
            } catch {
                localError = error
            }
        }

        if let error = coordinatorError ?? localError {
            throw error
        }

        guard let data = fileData else {
            throw NSError(domain: "Failed to read file data", code: -1, userInfo: nil)
        }

        let storage = Storage.storage()
        let storageRef = storage.reference()
        let originalFilename = file.lastPathComponent
        let documentRef = storageRef.child("docs/\(userId)/\(originalFilename)")

        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        metadata.customMetadata = ["originalFilename": originalFilename]

        do {
            _ = try await documentRef.putDataAsync(data, metadata: metadata)
            let downloadURL = try await documentRef.downloadURL()
            
            // Remove the port specification if present
            let urlString = downloadURL.absoluteString
            let cleanedURLString = urlString.replacingOccurrences(of: "https://firebasestorage.googleapis.com:443/", with: "https://firebasestorage.googleapis.com/")
            
            print("Document uploaded successfully. URL: \(cleanedURLString)")
            return cleanedURLString
        } catch {
            print("Error uploading document: \(error.localizedDescription)")
            throw error
        }
    }
    
    private var dangerSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Danger!")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Text("Delete Card")
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.red)
                    .cornerRadius(6)
                    .font(.system(size: 14))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func deleteBusinessCard() {
        Task { @MainActor in
            do {
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(Auth.auth().currentUser!.uid)
                
                // Check if the card being deleted is the primary card
                if editedCard.isPrimary {
                    // Update the user document to set primaryCardPlaceholder to true
                    await MainActor.run {
                        userRef.updateData([
                            "primaryCardPlaceholder": true,
                            "primaryCardId": FieldValue.delete()
                        ])
                    }
                }
                
                try await BusinessCard.delete(editedCard)
                print("Card deleted successfully")
                // Notify that a card was deleted
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .cardDeleted, object: nil)
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Error deleting card: \(error.localizedDescription)")
                // Here you might want to show an error alert to the user
            }
        }
    }
    
    private func fetchUserProStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                self.isPro = document.data()?["isPro"] as? Bool ?? false
            }
        }
    }
    
    private func deleteDocumentIfNeeded() async throws {
        guard let originalDocUrl = businessCard.cvUrl,
              let url = URL(string: originalDocUrl) else {
            return
        }

        // Extract the file path from the URL
        let components = url.pathComponents
        if let docIndex = components.firstIndex(of: "docs"),
           docIndex + 2 < components.count {
            let filePath = "docs/\(components[docIndex + 1])/\(components[docIndex + 2])"
            
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let documentRef = storageRef.child(filePath)
            
            try await documentRef.delete()
        }
    }
    
    init(businessCard: Binding<BusinessCard>, username: String) {
        self._businessCard = businessCard
        var initialCard = businessCard.wrappedValue
        self._editedCard = State(initialValue: initialCard)
        self.username = username
    }
}
