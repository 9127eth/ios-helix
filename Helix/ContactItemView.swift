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
    @State private var showingContactDetails = false
    
    var body: some View {
        ZStack {
            // Background shadow layer for depth effect
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.5))
                .offset(x: 4, y: 4) // Smaller offset since contact items are smaller than cards
            
            // Main content (existing view)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    // Contact details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contact.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.bodyPrimaryText)
                            .lineLimit(1)
                            .onTapGesture {
                                showingContactDetails = true
                            }
                        
                        if let company = contact.company {
                            Text(company)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Quick action buttons
                    HStack(spacing: 20) {
                        if contact.phone != nil || contact.email != nil {
                            Button(action: { showingContactOptions = true }) {
                                Image("email")
                                    .foregroundColor(AppColors.foreground)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                        }
                        
                        // Menu button
                        Menu {
                            Button {
                                showingContactDetails = true
                            } label: {
                                Label {
                                    Text("View")
                                } icon: {
                                    Image("person")
                                        .foregroundColor(AppColors.foreground)
                                }
                            }
                            
                            Button {
                                showingEditSheet = true
                            } label: {
                                Label {
                                    Text("Edit")
                                } icon: {
                                    Image("pencilEdit")
                                        .foregroundColor(AppColors.foreground)
                                }
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label {
                                    Text("Delete")
                                } icon: {
                                    Image("trashDelete")
                                        .foregroundColor(AppColors.foreground)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(AppColors.foreground)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .frame(height: 72)
                .padding(.horizontal, 16)
                .background(AppColors.cardGridBackground)
                .cornerRadius(12)
                .sheet(isPresented: $showingContactOptions) {
                    ContactOptionsSheet(contact: contact)
                        .presentationDetents([.height(250)])
                }
                .alert("Delete Contact", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) { deleteContact() }
                } message: {
                    Text("Are you sure you want to delete this contact? This action cannot be undone.")
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditContactView(contact: $contact)
                }
                .sheet(isPresented: $showingContactDetails) {
                    SeeContactView(contact: contact)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func deleteContact() {
        guard let userId = Auth.auth().currentUser?.uid,
              let contactId = contact.id else { return }
        
        Task {
            do {
                if let imageUrl = contact.imageUrl {
                    do {
                        try await Contact.deleteImage(url: imageUrl)
                    } catch let error as StorageErrorCode {
                        if error == .objectNotFound {
                            print("Warning: Image file not found in storage, continuing with deletion")
                        } else {
                            throw error
                        }
                    }
                }
                
                let db = Firestore.firestore()
                try await db.collection("users").document(userId)
                    .collection("contacts")
                    .document(contactId)
                    .delete()
                
            } catch {
                print("Error deleting contact: \(error)")
            }
        }
    }
}

struct InitialsView: View {
    let initials: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.cardDepthDefault)
                .frame(width: 40, height: 40)
            
            Text(initials)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }
} 