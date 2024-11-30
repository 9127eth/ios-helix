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
    
    init(contact: Binding<Contact>) {
        self._contact = contact
        self._editedContact = State(initialValue: contact.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Same form fields as CreateContactView
                // But populated with editedContact data
            }
            .navigationTitle("Edit Contact")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
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
}

