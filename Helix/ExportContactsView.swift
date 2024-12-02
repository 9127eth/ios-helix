import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ExportContactsView: View {
    let selectedContactIds: Set<String>
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var emailAddress = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email Address", text: $emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Export will be sent to")
                } footer: {
                    Text("A CSV file containing the selected contacts will be emailed to this address")
                }
            }
            .navigationTitle("Export Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportContacts()
                    }
                    .disabled(emailAddress.isEmpty || isProcessing)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Set default email to user's email
            if let userEmail = Auth.auth().currentUser?.email {
                emailAddress = userEmail
            }
        }
    }
    
    private func exportContacts() {
        guard !emailAddress.isEmpty else { return }
        isProcessing = true
        
        Task {
            do {
                guard let userId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                // Fetch selected contacts
                let db = Firestore.firestore()
                let contactsRef = db.collection("users").document(userId).collection("contacts")
                
                var contacts: [Contact] = []
                for contactId in selectedContactIds {
                    let snapshot = try await contactsRef.document(contactId).getDocument()
                    if let contact = try? snapshot.data(as: Contact.self) {
                        contacts.append(contact)
                    }
                }
                
                // Generate CSV content
                let csvContent = generateCSV(from: contacts)
                
                // Call your backend API to send the email with CSV
                try await sendExportEmail(to: emailAddress, csvContent: csvContent)
                
                await MainActor.run {
                    dismiss()
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    private func generateCSV(from contacts: [Contact]) -> String {
        // CSV header
        var csv = "Name,Company,Position,Phone,Email,Tags,Date Added\n"
        
        // Add contact rows
        for contact in contacts {
            let tags = (contact.tags ?? []).joined(separator: "; ")
            let row = [
                contact.name,
                contact.company ?? "",
                contact.position ?? "",
                contact.phone ?? "",
                contact.email ?? "",
                tags,
                formatDate(contact.dateAdded)
            ].map { escapeCSVField($0) }.joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func sendExportEmail(to email: String, csvContent: String) async throws {
        // Implement your email sending logic here
        // This could be a call to a Cloud Function or your backend API
        // For now, we'll just simulate the API call
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        // TODO: Replace with actual API call
        // Example:
        // let response = try await APIClient.shared.sendExportEmail(
        //     to: email,
        //     csvContent: csvContent
        // )
    }
} 