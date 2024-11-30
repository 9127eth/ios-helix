import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

struct CreateContactView: View {
    @Environment(\.dismiss) var dismiss
    @State private var contact = Contact(name: "")
    @State private var showCancelConfirmation = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPhoneNumberValid = true
    @State private var isEmailValid = true
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var availableTags: [Tag] = []
    @State private var selectedTags: Set<String> = []
    @State private var newTagName = ""
    @State private var showingTagInput = false
    
    struct Tag: Identifiable, Hashable {
        let id: String
        let name: String
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section(header: Text("Basic Information")) {
                    TextField("Name*", text: $contact.name)
                    TextField("Position", text: Binding(
                        get: { contact.position ?? "" },
                        set: { contact.position = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Company", text: Binding(
                        get: { contact.company ?? "" },
                        set: { contact.company = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                // Contact Information Section
                Section(header: Text("Contact Information")) {
                    TextField("Phone", text: Binding(
                        get: { contact.phone ?? "" },
                        set: { 
                            let newValue = $0.isEmpty ? nil : $0
                            contact.phone = newValue
                            validatePhone(newValue)
                        }
                    ))
                    .keyboardType(.phonePad)
                    if !isPhoneNumberValid {
                        Text("Please enter a valid phone number")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    TextField("Email", text: Binding(
                        get: { contact.email ?? "" },
                        set: { 
                            let newValue = $0.isEmpty ? nil : $0
                            contact.email = newValue
                            validateEmail(newValue)
                        }
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    if !isEmailValid {
                        Text("Please enter a valid email address")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    TextField("Address", text: Binding(
                        get: { contact.address ?? "" },
                        set: { contact.address = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                // Tags Section
                Section(header: Text("Tags")) {
                    ForEach(Array(selectedTags), id: \.self) { tagId in
                        if let tag = availableTags.first(where: { $0.id == tagId }) {
                            Text(tag.name)
                        }
                    }
                    
                    Button(action: { showingTagInput.toggle() }) {
                        Label("Add Tag", systemImage: "tag")
                    }
                }
                
                // Image Upload Section
                Section(header: Text("Business Card Image")) {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        if selectedImageData != nil {
                            Label("Change Image", systemImage: "photo")
                        } else {
                            Label("Select Image", systemImage: "photo")
                        }
                    }
                }
                
                // Notes Section
                Section(header: Text("Notes")) {
                    TextEditor(text: Binding(
                        get: { contact.note ?? "" },
                        set: { contact.note = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(height: 100)
                }
            }
            .navigationTitle("Create Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showCancelConfirmation = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(contact.name.isEmpty || !isPhoneNumberValid || !isEmailValid)
                }
            }
        }
        .sheet(isPresented: $showingTagInput) {
            TagSelectionView(
                availableTags: availableTags,
                selectedTags: $selectedTags,
                newTagName: $newTagName
            )
        }
        .alert("Discard Changes?", isPresented: $showCancelConfirmation) {
            Button("Continue Editing", role: .cancel) { }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to discard this contact?")
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            fetchTags()
        }
    }
    
    private func validatePhone(_ phone: String?) {
        guard let phone = phone, !phone.isEmpty else {
            isPhoneNumberValid = true
            return
        }
        // Add your phone validation logic here
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
    
    private func fetchTags() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("tags")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching tags: \(error)")
                    return
                }
                
                availableTags = snapshot?.documents.compactMap { doc in
                    Tag(id: doc.documentID, name: doc["name"] as? String ?? "")
                } ?? []
            }
    }
    
    private func saveContact() {
        guard !contact.name.isEmpty else {
            showAlert = true
            alertMessage = "Please enter a name for the contact."
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        contact.dateAdded = Date()
        contact.dateModified = Date()
        contact.contactSource = .manual
        contact.tags = Array(selectedTags)
        
        let db = Firestore.firestore()
        
        // Handle image upload if selected
        if let imageData = selectedImageData {
            // Use Task to handle async operation
            Task {
                do {
                    let imageUrl = try await Contact.uploadImage(imageData)
                    contact.imageUrl = imageUrl
                    saveContactToFirestore(db, userId)
                } catch {
                    await MainActor.run {
                        showAlert = true
                        alertMessage = "Error uploading image: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            saveContactToFirestore(db, userId)
        }
    }
    
    private func saveContactToFirestore(_ db: Firestore, _ userId: String) {
        do {
            try db.collection("users").document(userId)
                .collection("contacts")
                .addDocument(from: contact)
            dismiss()
        } catch {
            showAlert = true
            alertMessage = "Error saving contact: \(error.localizedDescription)"
        }
    }
}

struct TagSelectionView: View {
    let availableTags: [CreateContactView.Tag]
    @Binding var selectedTags: Set<String>
    @Binding var newTagName: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableTags) { tag in
                    Button(action: {
                        if selectedTags.contains(tag.id) {
                            selectedTags.remove(tag.id)
                        } else {
                            selectedTags.insert(tag.id)
                        }
                    }) {
                        HStack {
                            Text(tag.name)
                            Spacer()
                            if selectedTags.contains(tag.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Section(header: Text("Create New Tag")) {
                    TextField("Tag Name", text: $newTagName)
                    Button("Add Tag") {
                        // Implement add new tag logic
                    }
                    .disabled(newTagName.isEmpty)
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 