import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import ContactsUI

struct SeeContactView: View {
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @StateObject private var tagManager = TagManager()
    @State private var showingZoomableImage = false
    @State private var showingContactOptions = false
    @State private var shareImage: UIImage?
    @State private var showingShareSheet = false
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                // Add padding at the top
                Section {
                    EmptyView()
                }
                .listRowBackground(Color.clear)
                .frame(height: 20)
                
                Section {
                    HStack {
                        Text(contact.name)
                            .textSelection(.enabled)
                        Spacer()
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let position = contact.position {
                        HStack {
                            Text(position)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Position")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let company = contact.company {
                        HStack {
                            Text(company)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Company")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let phone = contact.phone {
                        HStack {
                            Text(phone)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Phone")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let email = contact.email {
                        HStack {
                            Text(email)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let website = contact.website {
                        HStack {
                            Text(website)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Website")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let address = contact.address {
                        HStack {
                            Text(address)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Address")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if let tags = contact.tags, !tags.isEmpty {
                    Section {
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
                                        showingZoomableImage = true
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
                                        Image(systemName: "phone.fill")
                                        Text("Call")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .tint(.green)
                                .buttonStyle(.borderedProminent)
                                
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
                                        Image(systemName: "message.fill")
                                        Text("Text")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .tint(.green)
                                .buttonStyle(.borderedProminent)
                            }
                            
                            if let email = contact.email {
                                Button {
                                    if let url = URL(string: "mailto:\(email)") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                        Text("Email")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .tint(.green)
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        
                        // Save to Contacts button
                        Button {
                            saveToContacts()
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("Save to Contacts")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        // Export button
                        Button {
                            showingExportSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
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
                        showingEditSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditContactView(contact: .constant(contact))
        }
        .sheet(isPresented: $showingZoomableImage) {
            if let imageUrl = contact.imageUrl {
                ZoomableImageView(imageUrl: imageUrl)
            }
        }
        .sheet(isPresented: $showingContactOptions) {
            ContactOptionsSheet(contact: contact)
                .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .onAppear {
            tagManager.fetchTags()
        }
    }
    
    private func shareImage(imageUrl: String) {
        guard let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let uiImage = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self.shareImage = uiImage
                self.showingShareSheet = true
            }
        }.resume()
    }
    
    private func saveToContacts() {
        let newContact = CNMutableContact()
        
        // Set name
        let nameComponents = contact.name.components(separatedBy: " ")
        newContact.givenName = nameComponents.first ?? ""
        if nameComponents.count > 1 {
            newContact.familyName = nameComponents.dropFirst().joined(separator: " ")
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
        
        // Save contact
        let store = CNContactStore()
        let saveRequest = CNSaveRequest()
        saveRequest.add(newContact, toContainerWithIdentifier: nil)
        
        do {
            try store.execute(saveRequest)
            // Show success message
        } catch {
            // Show error message
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