//
//  EditContactView.swift
//  Helix
//
//  Created by Richard Waithe on 11/30/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI
import FirebaseStorage

struct EditContactView: View {
    @Environment(\.dismiss) var dismiss
    @State private var editedContact: Contact
    @Binding var contact: Contact
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isPhoneNumberValid = true
    @State private var isEmailValid = true
    @State private var selectedTagIds: Set<String> = []
    @StateObject private var tagManager = TagManager()
    @State private var showingTagSheet = false
    @State private var showingCancelConfirmation = false
    @State private var imageToDelete: String? = nil
    @State private var pendingImageData: Data? = nil
    @FocusState private var focusedField: Field?
    @State private var showingDeleteConfirmation = false
    
    init(contact: Binding<Contact>) {
        self._contact = contact
        self._editedContact = State(initialValue: contact.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("Basic Information")) {
                    HStack {
                        TextField("Name*", text: $editedContact.name)
                            .focused($focusedField, equals: .name)
                            .onSubmit { focusedField = .position }
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Position", text: Binding(
                            get: { editedContact.position ?? "" },
                            set: { editedContact.position = $0.isEmpty ? nil : $0 }
                        ))
                        .focused($focusedField, equals: .position)
                        .onSubmit { focusedField = .company }
                        .multilineTextAlignment(.leading)
                        Spacer()
                        Text("Position")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Company", text: Binding(
                            get: { editedContact.company ?? "" },
                            set: { editedContact.company = $0.isEmpty ? nil : $0 }
                        ))
                        .focused($focusedField, equals: .company)
                        .onSubmit { focusedField = .phone }
                        .multilineTextAlignment(.leading)
                        Spacer()
                        Text("Company")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Contact Information
                Section(header: Text("Contact Information")) {
                    VStack(alignment: .leading) {
                        HStack {
                            TextField("Phone", text: Binding(
                                get: { editedContact.phone ?? "" },
                                set: { 
                                    let newValue = $0.isEmpty ? nil : $0
                                    editedContact.phone = newValue
                                    validatePhone(newValue)
                                }
                            ))
                            .keyboardType(.phonePad)
                            .multilineTextAlignment(.leading)
                            Spacer()
                            Text("Phone")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if !isPhoneNumberValid {
                            Text("Please enter a valid phone number")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            TextField("Email", text: Binding(
                                get: { editedContact.email ?? "" },
                                set: { 
                                    let newValue = $0.isEmpty ? nil : $0
                                    editedContact.email = newValue
                                    validateEmail(newValue)
                                }
                            ))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.leading)
                            Spacer()
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if !isEmailValid {
                            Text("Please enter a valid email address")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        TextField("Website", text: Binding(
                            get: { editedContact.website ?? "" },
                            set: { editedContact.website = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .website)
                        .onSubmit { focusedField = .address }
                        .multilineTextAlignment(.leading)
                        Spacer()
                        Text("Website")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Address", text: Binding(
                            get: { editedContact.address ?? "" },
                            set: { editedContact.address = $0.isEmpty ? nil : $0 }
                        ))
                        .focused($focusedField, equals: .address)
                        .onSubmit { focusedField = .note }
                        .multilineTextAlignment(.leading)
                        Spacer()
                        Text("Address")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Image Upload Section
                Section(header: Text("Image")) {
                    VStack(alignment: .center, spacing: 12) {
                        if let imageData = selectedImageData {
                            Image(uiImage: UIImage(data: imageData)!)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .cornerRadius(12)
                        } else if let imageUrl = editedContact.imageUrl {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                            } placeholder: {
                                ProgressView()
                                    .frame(height: 200)
                            }
                        } else {
                            Image(systemName: "doc.text.image")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(AppColors.inputFieldBackground)
                                .cornerRadius(12)
                        }
                        
                        if editedContact.imageUrl != nil || selectedImageData != nil {
                            Button(role: .destructive) {
                                deleteImage()
                            } label: {
                                HStack(spacing: 8) {
                                    Image("trashDelete")
                                        .renderingMode(.template)
                                    Text("Remove Image")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.red)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(AppColors.cardGridBackground)
                                .cornerRadius(12)
                            }
                            .frame(maxWidth: 160)
                        } else {
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                Label("Add Image", systemImage: "doc.badge.plus")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                // Tags Section
                Section(header: Text("Tags")) {
                    if selectedTagIds.isEmpty {
                        Text("No tags selected")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(Array(selectedTagIds), id: \.self) { tagId in
                            if let tag = tagManager.availableTags.first(where: { $0.id == tagId }) {
                                HStack {
                                    Text(tag.name)
                                    Spacer()
                                    Button(action: {
                                        selectedTagIds.remove(tagId)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                }
                            }
                        }
                    }
                    
                    Text("Add Tags")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            print("Tag text tapped")
                            showingTagSheet.toggle()
                        }
                }
                
                // Notes Section
                Section(header: Text("Notes")) {
                    TextEditor(text: Binding(
                        get: { editedContact.note ?? "" },
                        set: { editedContact.note = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(height: 100)
                }
                
                // Add this new section at the bottom after the Notes section
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Contact")
                                .padding(.vertical, 8)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                     to: nil, from: nil, for: nil)
                    }
            )
            .navigationTitle("Edit Contact")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCancelConfirmation = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(editedContact.name.isEmpty || !isPhoneNumberValid || !isEmailValid)
                }
            }
        }
        .sheet(isPresented: $showingTagSheet, onDismiss: {
            print("Sheet dismissed")
        }) {
            TagSelectionView(tagManager: tagManager, selectedTagIds: $selectedTagIds)
        }
        .alert("Cancel Editing?", isPresented: $showingCancelConfirmation) {
            Button("Continue Editing", role: .cancel) { }
            Button("Yes, I'm sure", role: .destructive) {
                // Reset all image-related state
                imageToDelete = nil
                pendingImageData = nil
                selectedImageData = nil
                selectedImage = nil
                dismiss()
            }
        } message: {
            Text("If you cancel without saving, any changes will be lost.")
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Delete Contact?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteContact()
            }
        } message: {
            Text("Are you sure you want to delete this contact? This action cannot be undone.")
        }
        .onAppear {
            print("Available tags: \(tagManager.availableTags.count)")
            selectedTagIds = Set(editedContact.tags ?? [])
            tagManager.fetchTags()
        }
        .onChange(of: selectedImage) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        pendingImageData = data
                        selectedImageData = data
                        
                        if let existingUrl = editedContact.imageUrl {
                            imageToDelete = existingUrl
                        }
                    }
                }
            }
        }
        .onChange(of: showingTagSheet) { newValue in
            print("showingTagSheet changed to: \(newValue)")
        }
    }
    
    private func saveChanges() {
        Task {
            do {
                guard let userId = Auth.auth().currentUser?.uid,
                      let contactId = contact.id else {
                    print("Error: Missing userId or contactId")
                    return
                }
                
                var updatedContact = editedContact
                
                // Parse the full name into first and last name
                let nameComponents = updatedContact.name.trimmingCharacters(in: .whitespacesAndNewlines)
                                                 .components(separatedBy: " ")
                updatedContact.firstName = nameComponents.first ?? ""
                updatedContact.lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : nil
                
                updatedContact.dateModified = Date()
                updatedContact.tags = Array(selectedTagIds)
                
                // Handle image changes first
                if let imageToDelete = imageToDelete {
                    try await Contact.deleteImage(url: imageToDelete)
                    updatedContact.imageUrl = nil
                    editedContact.imageUrl = nil  // Update the local state as well
                }
                
                if let newImageData = pendingImageData {
                    let imageUrl = try await Contact.uploadImage(newImageData)
                    updatedContact.imageUrl = imageUrl
                }
                
                // Debug print after image handling
                print("Attempting to save contact with data:", updatedContact)
                
                // Convert to dictionary AFTER image handling
                let contactData = try updatedContact.asDictionary()
                print("Encoded contact data:", contactData)
                
                let db = Firestore.firestore()
                let contactRef = db.collection("users").document(userId)
                    .collection("contacts").document(contactId)
                
                // Update the document with merge: false to ensure removed fields are deleted
                try await contactRef.setData(contactData)
                
                await MainActor.run {
                    contact = updatedContact
                    dismiss()
                }
                
            } catch {
                print("Save error details:", error)
                await MainActor.run {
                    showAlert = true
                    alertMessage = "Error saving changes: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func validatePhone(_ phone: String?) {
        guard let phone = phone, !phone.isEmpty else {
            isPhoneNumberValid = true
            return
        }
        isPhoneNumberValid = phone.count >= 10
    }
    
    private func validateEmail(_ email: String?) {
        guard let email = email, !email.isEmpty else {
            isEmailValid = true
            return
        }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        isEmailValid = emailPredicate.evaluate(with: email)
    }
    
    private func deleteImage() {
        // If there's an existing image URL, mark it for deletion
        if let existingUrl = editedContact.imageUrl {
            imageToDelete = existingUrl
        }
        
        // Reset all image-related state
        editedContact.imageUrl = nil
        pendingImageData = nil
        selectedImageData = nil
        selectedImage = nil
    }
    
    private func deleteContact() {
        Task {
            do {
                guard let userId = Auth.auth().currentUser?.uid,
                      let contactId = contact.id else {
                    print("Error: Missing userId or contactId")
                    return
                }
                
                let db = Firestore.firestore()
                let contactRef = db.collection("users").document(userId)
                    .collection("contacts").document(contactId)
                
                // Try to delete the image if it exists
                if let imageUrl = contact.imageUrl {
                    do {
                        try await Contact.deleteImage(url: imageUrl)
                    } catch let error as NSError {
                        // If the error is that the file doesn't exist, continue
                        if error.domain == StorageErrorDomain && 
                           error.code == StorageErrorCode.objectNotFound.rawValue {
                            print("Warning: Image file not found in storage, continuing with deletion")
                        } else {
                            // For other errors, throw them
                            throw error
                        }
                    }
                }
                
                // Delete the contact document
                try await contactRef.delete()
            } catch {
                print("Error deleting contact: \(error.localizedDescription)")
            }
        }
    }
}


