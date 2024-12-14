import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

struct ExportContactsView: View {
    let selectedContactIds: Set<String>
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var emailAddress = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    @StateObject private var tagManager = TagManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email Address", text: $emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Enter the email address to send export")
                } footer: {
                    Text("A CSV file containing the selected contacts will be emailed to this address")
                }
            }
            .padding(.top, 120)
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
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The export has been sent successfully.")
        }
        .onAppear {
            // Set default email to user's email
            if let userEmail = Auth.auth().currentUser?.email {
                emailAddress = userEmail
            }
            tagManager.fetchTags()
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
        var csv = "Full Name,First Name,Last Name,Company,Position,Phone,Email,Tags,Date Added\n"
        
        // Sort contacts alphabetically by name
        let sortedContacts = contacts.sorted { $0.name.trimmingCharacters(in: .whitespaces).lowercased() < $1.name.trimmingCharacters(in: .whitespaces).lowercased() }
        
        // Add contact rows
        for contact in sortedContacts {
            // Get tag names instead of IDs
            let tagNames = (contact.tags ?? []).compactMap { tagId in
                tagManager.availableTags.first(where: { $0.id == tagId })?.name
            }.joined(separator: "; ")
            
            let row = [
                contact.name,
                contact.firstName ?? "",
                contact.lastName ?? "",
                contact.company ?? "",
                contact.position ?? "",
                contact.phone ?? "",
                contact.email ?? "",
                tagNames,
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
        guard let url = URL(string: "\(AppEnvironment.apiBaseURL)/send-email") else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppEnvironment.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "type": "csvExport",
            "email": email,
            "csvData": csvContent,
            "fileName": "helix_contacts_export.csv"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: -1, userInfo: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(
                domain: "Server error",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Failed to send export email"]
            )
        }
        
        await MainActor.run {
            showSuccessAlert = true
            // Add delay before dismissing
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
                onComplete()
            }
        }
    }
} 