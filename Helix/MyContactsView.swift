//
//  MyContactsView.swift
//  Helix
//
//  Created by Richard Waithe on 11/30/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyContactsView: View {
    @State private var contacts: [Contact] = []
    @State private var showingAddContact = false
    @State private var searchText = ""
    @State private var selectedSortOption = SortOption.name
    @State private var selectedTags: Set<String> = []
    @State private var showingTagManager = false
    @State private var selectedContacts: Set<String> = []
    @State private var showingExportModal = false
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = false
    @State private var showSubscriptionView = false
    @Binding var isPro: Bool
    
    enum SortOption {
        case name, dateAdded
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    if !isPro {
                        Button(action: {
                            showSubscriptionView = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12)
                                Text("Get Helix Pro")
                                    .font(.subheadline)
                            }
                            .foregroundColor(AppColors.helixPro)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.10))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        .padding(.bottom, 5)
                    }
                    
                    Text("Contacts")
                        .font(.system(size: 60, weight: .bold))
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.bodyPrimaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 40)
                
                // Add Contact and Manage Tags buttons
                HStack {
                    Spacer()
                    Button(action: {
                        showingTagManager = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "tag")
                                .renderingMode(.template)
                            Text("Manage Tags")
                                .font(.footnote)
                        }
                        .foregroundColor(AppColors.buttonText)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(AppColors.cardGridBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .padding(.trailing, 8)
                    
                    AddContactButton {
                        showingAddContact = true
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                // Search and filters
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    HStack {
                        TagFilterButton(selectedTags: $selectedTags)
                        Spacer()
                        SortButton(selectedOption: $selectedSortOption)
                    }
                    .padding(.horizontal)
                }
                
                // Contacts list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredContacts) { contact in
                            ContactItemView(contact: Binding(
                                get: { contact },
                                set: { newValue in
                                    if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                                        contacts[index] = newValue
                                    }
                                }
                            ))
                                .onTapGesture {
                                    toggleSelection(contact.id ?? "")
                                }
                        }
                    }
                    .padding()
                }
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView(isPro: $isPro)
            }
            .sheet(isPresented: $showingAddContact) {
                CreateContactView()
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagerView()
            }
        }
        .onAppear {
            fetchContacts()
        }
    }
    
    private var filteredContacts: [Contact] {
        var result = contacts
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { contact in
                let searchContent = "\(contact.name) \(contact.company ?? "")"
                return searchContent.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply tag filter
        if !selectedTags.isEmpty {
            result = result.filter { contact in
                guard let contactTags = contact.tags else { return false }
                return !Set(contactTags).isDisjoint(with: selectedTags)
            }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .name:
            result.sort { $0.name < $1.name }
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        }
        
        return result
    }
    
    private func toggleSelection(_ contactId: String) {
        if selectedContacts.contains(contactId) {
            selectedContacts.remove(contactId)
        } else {
            selectedContacts.insert(contactId)
        }
    }
    
    private func fetchContacts() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("contacts")
            .order(by: "dateAdded", descending: true)
            .addSnapshotListener { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error fetching contacts: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                contacts = documents.compactMap { document in
                    try? document.data(as: Contact.self)
                }
            }
    }
}