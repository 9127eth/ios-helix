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
    
    enum SortOption {
        case name, dateAdded
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Contacts")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.bodyPrimaryText)
                    Spacer()
                    
                    if !selectedContacts.isEmpty {
                        HStack(spacing: 16) {
                            Button(action: { showingExportModal = true }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(AppColors.foreground)
                            }
                            
                            Button(action: { showingDeleteConfirmation = true }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
                .background(AppColors.barMenuBackground)
                
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
                            ContactItemView(contact: contact)
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