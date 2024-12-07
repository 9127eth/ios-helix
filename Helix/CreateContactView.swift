import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

enum Field: Hashable {
    case name
    case position
    case company
    case phone
    case email
    case address
    case note
    case website
}

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
    @StateObject private var tagManager = TagManager()
    @State private var selectedTagIds: Set<String> = []
    @State private var showingTagSheet = false
    @FocusState private var focusedField: Field?
    
    // OCR-related properties
    var prefilledData: ScannedContactData?
    @State private var pendingImage: UIImage?
    
    init(prefilledData: ScannedContactData? = nil) {
        self.prefilledData = prefilledData
        
        // Create contact with basic name
        var initialContact = Contact(name: prefilledData?.name ?? "")
        
        // Then set additional properties if they exist
        if let prefilledData = prefilledData {
            initialContact.email = prefilledData.email
            initialContact.phone = prefilledData.phone
            initialContact.company = prefilledData.company
            initialContact.position = prefilledData.position
            initialContact.website = prefilledData.website
            initialContact.address = prefilledData.address
        }
        
        // Initialize the state
        _contact = State(initialValue: initialContact)
        _pendingImage = State(initialValue: prefilledData?.capturedImage)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // OCR confidence indicators
                if let prefilledData = prefilledData {
                    Section {
                        ForEach(prefilledData.lowConfidenceFields, id: \.self) { field in
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.yellow)
                                Text("Please verify the \(field)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Basic Information Section
                Section(header: Text("Basic Information")) {
                    TextField("Name*", text: $contact.name)
                        .focused($focusedField, equals: .name)
                        .onSubmit { focusedField = .position }
                    
                    TextField("Position", text: Binding(
                        get: { contact.position ?? "" },
                        set: { contact.position = $0.isEmpty ? nil : $0 }
                    ))
                    .focused($focusedField, equals: .position)
                    .onSubmit { focusedField = .company }
                    
                    TextField("Company", text: Binding(
                        get: { contact.company ?? "" },
                        set: { contact.company = $0.isEmpty ? nil : $0 }
                    ))
                    .focused($focusedField, equals: .company)
                    .onSubmit { focusedField = .phone }
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
                    
                    TextField("Website", text: Binding(
                        get: { contact.website ?? "" },
                        set: { contact.website = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .website)
                    .onSubmit { focusedField = .address }
                    
                    TextField("Address", text: Binding(
                        get: { contact.address ?? "" },
                        set: { contact.address = $0.isEmpty ? nil : $0 }
                    ))
                        .focused($focusedField, equals: .address)
                        .onSubmit { focusedField = .note }
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
                
                // Image Upload Section
                Section(header: Text("Business Card Image")) {
                    VStack {
                        if let imageData = selectedImageData {
                            Image(uiImage: UIImage(data: imageData)!)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .cornerRadius(12)
                        } else if let scannedImage = pendingImage {
                            Image(uiImage: scannedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .cornerRadius(12)
                        }
                        
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            if selectedImageData != nil || pendingImage != nil {
                                Label("Change Image", systemImage: "photo")
                            } else {
                                Label("Select Image", systemImage: "photo")
                            }
                        }
                        .onChange(of: selectedImage) { newValue in
                            print("Image selected")
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    print("Image data loaded: \(data.count) bytes")
                                    await MainActor.run {
                                        selectedImageData = data
                                        pendingImage = nil  // Clear scanned image when user selects new image
                                        print("Image data set to state")
                                    }
                                }
                            }
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
        .sheet(isPresented: $showingTagSheet) {
            TagSelectionView(tagManager: tagManager, selectedTagIds: $selectedTagIds)
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
            tagManager.fetchTags()
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
    
    private func saveContact() {
        guard !contact.name.isEmpty else {
            showAlert = true
            alertMessage = "Please enter a name for the contact."
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Parse the full name into first and last name
        let nameComponents = contact.name.trimmingCharacters(in: .whitespacesAndNewlines)
                                      .components(separatedBy: " ")
        contact.firstName = nameComponents.first ?? ""
        contact.lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : nil
        
        contact.dateAdded = Date()
        contact.dateModified = Date()
        contact.contactSource = .manual
        contact.tags = Array(selectedTagIds)
        
        // Save last used tag
        if let lastTag = selectedTagIds.first {
            tagManager.lastUsedTagId = lastTag
        }
        
        let db = Firestore.firestore()
        
        Task {
            do {
                // Handle image upload first if we have a scanned image
                if let imageToUpload = pendingImage {
                    if let imageData = imageToUpload.jpegData(compressionQuality: 0.8) {
                        let imageUrl = try await Contact.uploadImage(imageData)
                        contact.imageUrl = imageUrl
                    }
                }
                
                try await db.collection("users").document(userId)
                    .collection("contacts")
                    .addDocument(from: contact)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    showAlert = true
                    alertMessage = "Error saving contact: \(error.localizedDescription)"
                }
            }
        }
    }
} 