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
    @State private var showingContactOptions = false
    
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
            
            // Image preview
            if let imageUrl = contact.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 40)
                        .clipped()
                        .cornerRadius(6)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 40)
                        .cornerRadius(6)
                }
            }
            
            // Quick action buttons
            HStack(spacing: 20) {
                if contact.phone != nil || contact.email != nil {
                    Button(action: { showingContactOptions = true }) {
                        Image(systemName: "envelope")
                            .foregroundColor(AppColors.foreground)
                            .frame(width: 44, height: 60)
                            .contentShape(Rectangle())
                    }
                    .padding(.leading, 8)
                }
                
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppColors.foreground)
                        .frame(width: 44, height: 60)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding()
        .background(AppColors.cardGridBackground)
        .cornerRadius(12)
        .sheet(isPresented: $showingContactOptions) {
            ContactOptionsSheet(contact: contact)
                .presentationDetents([.height(250)])
        }
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