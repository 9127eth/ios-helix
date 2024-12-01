import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct ContactItemView: View {
    @Binding var contact: Contact
    @State private var showingActionSheet = false
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.bodyPrimaryText)
                
                if let position = contact.position {
                    Text(position)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                }
                
                if let company = contact.company {
                    Text(company)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Quick action buttons
            HStack(spacing: 12) {
                if let phone = contact.phone {
                    Button(action: { callPhone(phone) }) {
                        Image(systemName: "phone")
                            .foregroundColor(AppColors.foreground)
                    }
                    
                    Button(action: { sendText(phone) }) {
                        Image(systemName: "message")
                            .foregroundColor(AppColors.foreground)
                    }
                }
                
                if let email = contact.email {
                    Button(action: { sendEmail(email) }) {
                        Image(systemName: "envelope")
                            .foregroundColor(AppColors.foreground)
                    }
                }
                
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppColors.foreground)
                }
            }
        }
        .padding()
        .background(AppColors.cardGridBackground)
        .cornerRadius(12)
        .confirmationDialog("Contact Actions", isPresented: $showingActionSheet) {
            Button("Edit") { showingEditSheet = true }
            Button("Share") { showingShareSheet = true }
            Button("Delete", role: .destructive) { showingDeleteAlert = true }
        }
        .alert("Delete Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteContact() }
        } message: {
            Text("Are you sure you want to delete this contact?")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditContactView(contact: $contact)
        }
    }
    
    private func callPhone(_ number: String) {
        if let url = URL(string: "tel://\(number)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendText(_ number: String) {
        if let url = URL(string: "sms://\(number)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func deleteContact() {
        guard let userId = Auth.auth().currentUser?.uid,
              let contactId = contact.id else { return }
        
        Task {
            do {
                // Delete image if exists
                if let imageUrl = contact.imageUrl {
                    try await Contact.deleteImage(url: imageUrl)
                }
                
                // Delete contact document
                let db = Firestore.firestore()
                try await db.collection("users").document(userId)
                    .collection("contacts").document(contactId)
                    .delete()
                
            } catch {
                print("Error deleting contact: \(error.localizedDescription)")
            }
        }
    }
} 