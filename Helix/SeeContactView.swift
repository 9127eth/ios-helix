import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SeeContactView: View {
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @StateObject private var tagManager = TagManager()
    
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
                        Spacer()
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let position = contact.position {
                        HStack {
                            Text(position)
                            Spacer()
                            Text("Position")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let company = contact.company {
                        HStack {
                            Text(company)
                            Spacer()
                            Text("Company")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let phone = contact.phone {
                        HStack {
                            Text(phone)
                            Spacer()
                            Text("Phone")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let email = contact.email {
                        HStack {
                            Text(email)
                            Spacer()
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let website = contact.website {
                        HStack {
                            Text(website)
                            Spacer()
                            Text("Website")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let address = contact.address {
                        HStack {
                            Text(address)
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
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Image Section at the bottom
                if let imageUrl = contact.imageUrl {
                    Section {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .cornerRadius(12)
                        } placeholder: {
                            ProgressView()
                                .frame(height: 200)
                        }
                    }
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.large)
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
        .onAppear {
            tagManager.fetchTags()
        }
    }
} 