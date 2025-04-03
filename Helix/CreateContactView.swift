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
    var onSave: (() -> Void)? = nil
    
    // Add these state variables at the top with other @State properties
    @State private var showDuplicateAlert = false
    @State private var duplicateContact: Contact? = nil
    @State private var isSaving = false
    
    init(prefilledData: ScannedContactData? = nil, onSave: (() -> Void)? = nil) {
        self.prefilledData = prefilledData
        self.onSave = onSave
        
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
            initialContact.contactSource = .scanned
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
                    HStack {
                        TextField("Name*", text: $contact.name)
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
                            get: { contact.position ?? "" },
                            set: { contact.position = $0.isEmpty ? nil : $0 }
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
                            get: { contact.company ?? "" },
                            set: { contact.company = $0.isEmpty ? nil : $0 }
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
                
                // Contact Information Section
                Section(header: Text("Contact Information")) {
                    VStack(alignment: .leading) {
                        HStack {
                            TextField("Phone", text: Binding(
                                get: { contact.phone ?? "" },
                                set: { 
                                    let newValue = $0.isEmpty ? nil : $0
                                    contact.phone = newValue
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
                                get: { contact.email ?? "" },
                                set: { 
                                    let newValue = $0.isEmpty ? nil : $0
                                    contact.email = newValue
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
                            get: { contact.website ?? "" },
                            set: { contact.website = $0.isEmpty ? nil : $0 }
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
                            get: { contact.address ?? "" },
                            set: { contact.address = $0.isEmpty ? nil : $0 }
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
                                    Button {
                                        selectedTagIds.remove(tagId)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                    
                    Button {
                        focusedField = nil
                        showingTagSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image("tag")
                                .renderingMode(.template)
                            Text("Add Tags")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                }
                
                // Image Upload Section
                Section(header: Text("Business Card Image")) {
                    VStack(alignment: .center, spacing: 12) {
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
                                HStack(spacing: 8) {
                                    Image(systemName: "photo")
                                    Text("Change Image")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(AppColors.cardGridBackground)
                                .cornerRadius(12)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo")
                                    Text("Select Image")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(AppColors.cardGridBackground)
                                .cornerRadius(12)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
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
            .dismissKeyboardOnTap()
            .navigationTitle("Create Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showCancelConfirmation = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveContact()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.blue)
                            }
                            Text("Save")
                        }
                    }
                    .disabled(contact.name.isEmpty || !isPhoneNumberValid || !isEmailValid || isSaving)
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
        .alert("Duplicate Contact Found", isPresented: $showDuplicateAlert) {
            Button("Continue Saving", role: .destructive) {
                Task {
                    guard let userId = Auth.auth().currentUser?.uid else { return }
                    await saveContactToFirestore(db: Firestore.firestore(), userId: userId)
                }
            }
            Button("Go Back", role: .cancel) {
                isSaving = false
            }
        } message: {
            Text("A contact with this email already exists: \(duplicateContact?.name ?? "")")
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
        
        // Set loading state
        isSaving = true
        
        // Parse the full name into first and last name
        let nameComponents = contact.name.trimmingCharacters(in: .whitespacesAndNewlines)
                                      .components(separatedBy: " ")
        contact.firstName = nameComponents.first ?? ""
        contact.lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : nil
        
        contact.dateAdded = Date()
        contact.dateModified = Date()
        contact.tags = Array(selectedTagIds)
        
        // Save last used tag
        if let lastTag = selectedTagIds.first {
            tagManager.lastUsedTagId = lastTag
        }
        
        let db = Firestore.firestore()
        
        Task {
            do {
                // Check for duplicate email if email is provided
                if let email = contact.email {
                    let snapshot = try await db.collection("users").document(userId)
                        .collection("contacts")
                        .whereField("email", isEqualTo: email)
                        .getDocuments()
                    
                    if let existingContact = try snapshot.documents.first?.data(as: Contact.self) {
                        await MainActor.run {
                            duplicateContact = existingContact
                            showDuplicateAlert = true
                            isSaving = false
                        }
                        return
                    }
                }
                
                // Continue with normal save if no duplicate
                await saveContactToFirestore(db: db, userId: userId)
                
            } catch {
                await MainActor.run {
                    showAlert = true
                    alertMessage = "Error saving contact: \(error.localizedDescription)"
                    isSaving = false
                }
            }
        }
    }
    
    private func saveContactToFirestore(db: Firestore, userId: String) async {
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
                onSave?()
            }
        } catch {
            await MainActor.run {
                showAlert = true
                alertMessage = "Error saving contact: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
} 