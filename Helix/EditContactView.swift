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
    
    init(contact: Binding<Contact>) {
        self._contact = contact
        self._editedContact = State(initialValue: contact.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("Basic Information")) {
                    TextField("Name*", text: $editedContact.name)
                    TextField("Position", text: Binding(
                        get: { editedContact.position ?? "" },
                        set: { editedContact.position = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Company", text: Binding(
                        get: { editedContact.company ?? "" },
                        set: { editedContact.company = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                // Contact Information
                Section(header: Text("Contact Information")) {
                    TextField("Phone", text: Binding(
                        get: { editedContact.phone ?? "" },
                        set: { 
                            let newValue = $0.isEmpty ? nil : $0
                            editedContact.phone = newValue
                            validatePhone(newValue)
                        }
                    ))
                    .keyboardType(.phonePad)
                    
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
                    
                    TextField("Address", text: Binding(
                        get: { editedContact.address ?? "" },
                        set: { editedContact.address = $0.isEmpty ? nil : $0 }
                    ))
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.divider, lineWidth: 1)
                                )
                        } else if let imageUrl = editedContact.imageUrl {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.divider, lineWidth: 1)
                                    )
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.divider, lineWidth: 1)
                                )
                        }
                        
                        HStack(spacing: 16) {
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                Label(selectedImageData != nil ? "Change Image" : "Add Image", systemImage: "doc.badge.plus")
                                    .foregroundColor(.blue)
                            }
                            
                            if editedContact.imageUrl != nil || selectedImageData != nil {
                                Button(role: .destructive) {
                                    deleteImage()
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            }
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
                                    Button(action: { selectedTagIds.remove(tagId) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button(action: { showingTagSheet = true }) {
                        Label("Manage Tags", systemImage: "tag")
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
            }
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
        .sheet(isPresented: $showingTagSheet) {
            TagSelectionView(tagManager: tagManager, selectedTagIds: $selectedTagIds)
        }
        .alert("Cancel Editing?", isPresented: $showingCancelConfirmation) {
            Button("Continue Editing", role: .cancel) { }
            Button("Yes, I'm sure", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("If you cancel without saving, any changes will be lost.")
        }
        .onAppear {
            selectedTagIds = Set(editedContact.tags ?? [])
            tagManager.fetchTags()
        }
        .onChange(of: selectedImage) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        Task {
            do {
                if let imageData = selectedImageData {
                    let imageUrl = try await Contact.uploadImage(imageData)
                    editedContact.imageUrl = imageUrl
                }
                
                guard let userId = Auth.auth().currentUser?.uid,
                      let contactId = editedContact.id else { return }
                
                let db = Firestore.firestore()
                try await db.collection("users").document(userId)
                    .collection("contacts").document(contactId)
                    .setData(try editedContact.asDictionary(), merge: true)
                
                contact = editedContact
                dismiss()
            } catch {
                showAlert = true
                alertMessage = error.localizedDescription
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
        Task {
            if let imageUrl = editedContact.imageUrl {
                do {
                    try await Contact.deleteImage(url: imageUrl)
                    await MainActor.run {
                        editedContact.imageUrl = nil
                        selectedImage = nil
                        selectedImageData = nil
                    }
                } catch {
                    showAlert = true
                    alertMessage = "Failed to delete image: \(error.localizedDescription)"
                }
            } else {
                selectedImage = nil
                selectedImageData = nil
            }
        }
    }
}


