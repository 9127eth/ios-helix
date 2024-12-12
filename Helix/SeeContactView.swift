import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import ContactsUI

private struct ContactDetailRow: View {
    let content: String
    let label: String
    
    var body: some View {
        HStack {
            Text(content)
                .textSelection(.enabled)
            Spacer()
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct SeeContactView: View {
    @StateObject private var viewModel = SeeContactViewModel()
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    @StateObject private var tagManager = TagManager()
    
    var body: some View {
        NavigationView {
            ContactDetailsContent(
                contact: contact,
                viewModel: viewModel,
                tagManager: tagManager,
                dismiss: dismiss
            )
        }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            EditContactView(contact: .constant(contact))
        }
        .sheet(isPresented: $viewModel.showingZoomableImage) {
            if let imageUrl = contact.imageUrl {
                ZoomableImageView(imageUrl: imageUrl)
            }
        }
        .sheet(isPresented: $viewModel.showingContactOptions) {
            ContactOptionsSheet(contact: contact)
                .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let image = viewModel.shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .sheet(isPresented: $viewModel.showingExportSheet) {
            if let contactId = contact.id {
                ExportContactsView(
                    selectedContactIds: Set([contactId]),
                    onComplete: {
                        viewModel.showingExportSheet = false
                    }
                )
            }
        }
        .onAppear {
            tagManager.fetchTags()
        }
        .alert("Success", isPresented: $viewModel.showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Contact saved successfully")
        }
        .alert("Error", isPresented: $viewModel.showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Permission Required", isPresented: $viewModel.showingPermissionDenied) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        } message: {
            Text("Please enable contact access in Settings to save contacts")
        }
    }
}

private struct ContactDetailsContent: View {
    let contact: Contact
    @ObservedObject var viewModel: SeeContactViewModel
    @ObservedObject var tagManager: TagManager
    let dismiss: DismissAction
    
    var body: some View {
        Form {
            Section {
                EmptyView()
            }
            .listRowBackground(Color.clear)
            .frame(height: 20)
            
            Section {
                ContactDetailRow(content: contact.name, label: "Name")
                
                if let position = contact.position {
                    ContactDetailRow(content: position, label: "Position")
                }
                
                if let company = contact.company {
                    ContactDetailRow(content: company, label: "Company")
                }
                
                if let phone = contact.phone {
                    ContactDetailRow(content: phone, label: "Phone")
                }
                
                if let email = contact.email {
                    ContactDetailRow(content: email, label: "Email")
                }
                
                if let website = contact.website {
                    ContactDetailRow(content: website, label: "Website")
                }
                
                if let address = contact.address {
                    ContactDetailRow(content: address, label: "Address")
                }
            }
            
            if let tags = contact.tags, !tags.isEmpty {
                Section {
                    TagsList(tags: tags, tagManager: tagManager)
                }
            }
            
            if let note = contact.note {
                Section {
                    HStack {
                        Text(note)
                            .textSelection(.enabled)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Image Section
            if let imageUrl = contact.imageUrl {
                Section {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        VStack(spacing: 12) {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .onTapGesture {
                                    viewModel.showingZoomableImage = true
                                }
                                .contentShape(Rectangle())
                            
                            Button {
                                shareImage(imageUrl: imageUrl)
                            } label: {
                                HStack(spacing: 8) {
                                    Image("share.3")
                                        .renderingMode(.template)
                                    Text("Share Image")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(AppColors.buttonText)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(AppColors.secondary)
                                .cornerRadius(12)
                            }
                            .frame(maxWidth: 160)
                        }
                    } placeholder: {
                        ProgressView()
                            .frame(height: 200)
                    }
                }
            }
            
            // Add some spacing
            Section {
                EmptyView()
            }
            .listRowBackground(Color.clear)
            .frame(height: 20)
            
            // Action Buttons Section at the bottom
            Section {
                VStack(spacing: 12) {
                    // Communication buttons
                    HStack(spacing: 12) {
                        if let phone = contact.phone {
                            Button {
                                if let url = URL(string: "tel://\(phone)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image("phone")
                                    Text("Call")
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(AppColors.buttonText)
                                .padding(.vertical, 6)
                                .background(AppColors.primary)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                guard let phone = contact.phone else { return }
                                
                                // Step 1: Remove spaces and special characters
                                let noSpaces = phone.replacingOccurrences(of: " ", with: "")
                                let noHyphens = noSpaces.replacingOccurrences(of: "-", with: "")
                                let noParens = noHyphens.replacingOccurrences(of: "(", with: "")
                                    .replacingOccurrences(of: ")", with: "")
                                
                                // Step 2: Clean up
                                let cleaned = noParens.trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                // Step 3: Create and open URL
                                if let url = URL(string: "sms:\(cleaned)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image("textmessage")
                                    Text("Text")
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(AppColors.buttonText)
                                .padding(.vertical, 6)
                                .background(AppColors.primary)
                                .cornerRadius(12)
                            }
                        }
                        
                        if let email = contact.email {
                            Button {
                                if let url = URL(string: "mailto:\(email)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image("email")
                                    Text("Email")
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(AppColors.buttonText)
                                .padding(.vertical, 6)
                                .background(AppColors.primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Save to Contacts button
                    Button {
                        saveToContacts()
                    } label: {
                        HStack {
                            Image("savecontact")
                            Text("Save to Contacts")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(AppColors.buttonText)
                        .padding(.vertical, 6)
                        .background(AppColors.cardDepthDefault)
                        .cornerRadius(12)
                    }
                    
                    // Export button
                    Button {
                        viewModel.showingExportSheet = true
                    } label: {
                        HStack {
                            Image("csv")
                            Text("Export as CSV")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(AppColors.buttonText)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.large)
        .padding(.top, 10)
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    viewModel.showingEditSheet = true
                }
            }
        }
    }
    
    private func shareImage(imageUrl: String) {
        guard let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let uiImage = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self.viewModel.shareImage = uiImage
                self.viewModel.showingShareSheet = true
            }
        }.resume()
    }
    
    private func saveToContacts() {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    self.performContactSave(store: store)
                }
            } else {
                DispatchQueue.main.async {
                    self.viewModel.showingPermissionDenied = true
                }
            }
        }
    }
    
    private func performContactSave(store: CNContactStore) {
        let newContact = CNMutableContact()
        
        // Debug print
        print("Contact data being saved:")
        print("Name: \(contact.name)")
        print("Company: \(contact.company ?? "nil")")
        print("Phone: \(contact.phone ?? "nil")")
        print("Email: \(contact.email ?? "nil")")
        
        // Set name (improved splitting logic)
        let nameComponents = contact.name.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }
        
        if !nameComponents.isEmpty {
            newContact.givenName = nameComponents[0]
            if nameComponents.count > 1 {
                newContact.familyName = nameComponents[1...].joined(separator: " ")
            }
        }
        
        // Set organization
        if let company = contact.company {
            newContact.organizationName = company
        }
        
        // Set job title
        if let position = contact.position {
            newContact.jobTitle = position
        }
        
        // Set phone
        if let phone = contact.phone {
            newContact.phoneNumbers = [CNLabeledValue(
                label: CNLabelPhoneNumberMain,
                value: CNPhoneNumber(stringValue: phone)
            )]
        }
        
        // Set email
        if let email = contact.email {
            newContact.emailAddresses = [CNLabeledValue(
                label: CNLabelWork,
                value: email as NSString
            )]
        }
        
        // Set website
        if let website = contact.website {
            newContact.urlAddresses = [CNLabeledValue(
                label: CNLabelWork,
                value: website as NSString
            )]
        }
        
        // Set address
        if let address = contact.address {
            let postalAddress = CNMutablePostalAddress()
            postalAddress.street = address
            newContact.postalAddresses = [CNLabeledValue(
                label: CNLabelWork,
                value: postalAddress
            )]
        }
        
        // Save contact in background
        DispatchQueue.global(qos: .userInitiated).async {
            let saveRequest = CNSaveRequest()
            saveRequest.add(newContact, toContainerWithIdentifier: nil)
            
            do {
                try store.execute(saveRequest)
                DispatchQueue.main.async {
                    self.viewModel.showingSaveSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.viewModel.errorMessage = error.localizedDescription
                    self.viewModel.showingSaveError = true
                }
            }
        }
    }
}

struct ZoomableImageView: View {
    let imageUrl: String
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                scale = scale > 1 ? 1 : 2
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                } placeholder: {
                    ProgressView()
                }
            }
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class SeeContactViewModel: ObservableObject {
    @Published var showingEditSheet = false
    @Published var showingZoomableImage = false
    @Published var showingContactOptions = false
    @Published var shareImage: UIImage?
    @Published var showingShareSheet = false
    @Published var showingExportSheet = false
    @Published var showingSaveSuccess = false
    @Published var showingSaveError = false
    @Published var showingPermissionDenied = false
    @Published var errorMessage = ""
}

private struct TagsList: View {
    let tags: [String]
    @ObservedObject var tagManager: TagManager
    
    var body: some View {
        ForEach(tags, id: \.self) { tagId in
            if let tag = tagManager.availableTags.first(where: { $0.id == tagId }) {
                HStack {
                    Text(tag.name)
                        .textSelection(.enabled)
                    Spacer()
                    Text("Tag")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
} 