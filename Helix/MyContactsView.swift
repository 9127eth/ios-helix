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
    @State private var isSelectionMode = false
    @State private var selectedContactIds: Set<String> = []
    @State private var showingBulkActionSheet = false
    @State private var showingBulkTagSheet = false
    @State private var showingBulkDeleteConfirmation = false
    @State private var showingExportEmailSheet = false
    @Binding var isPro: Bool
    @FocusState private var isSearchFocused: Bool
    @State private var isShowingContactCreationEntry = false
    @State private var showUpgradeModal = false
    
    enum SortOption {
        case name, dateAdded
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                    .dismissKeyboardOnTap()
                
                VStack(spacing: 0) {
                    // Header with title
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
                    
                    // Action buttons row
                    HStack(spacing: 8) {
                        Button(action: {
                            showingTagManager = true
                        }) {
                            HStack(spacing: 8) {
                                Image("tag")
                                    .renderingMode(.template)
                                Text("Manage Tags")
                                    .font(.footnote)
                            }
                            .foregroundColor(AppColors.bodyPrimaryText)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(AppColors.cardGridBackground)
                            .cornerRadius(16)
                        }
                        .padding(.trailing, 8)
                        
                        Button(action: {
                            if !isPro && contacts.count >= 2 {
                                showUpgradeModal = true
                            } else {
                                isShowingContactCreationEntry = true
                            }
                        }) {
                            AddContactButton(action: {
                                if !isPro && contacts.count >= 2 {
                                    showUpgradeModal = true
                                } else {
                                    isShowingContactCreationEntry = true
                                }
                            })
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    
                    // Search and filters with Select button
                    VStack(spacing: 12) {
                        SearchBar(text: $searchText)
                            .focused($isSearchFocused)
                            .padding(.horizontal)
                        
                        HStack(spacing: 8) {
                            Button(action: { isSelectionMode.toggle() }) {
                                HStack(spacing: 8) {
                                    Image("select")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                    Text("Select")
                                        .font(.footnote)
                                }
                                .foregroundColor(isSelectionMode ? AppColors.buttonText : AppColors.bodyPrimaryText)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(isSelectionMode ? AppColors.buttonBackground : AppColors.cardGridBackground)
                                .cornerRadius(16)
                            }
                            
                            SortButton(selectedOption: $selectedSortOption)
                            TagFilterButton(selectedTags: $selectedTags)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Selection info bar (visible when in selection mode)
                        if isSelectionMode {
                            HStack {
                                Button(action: {
                                    if selectedContactIds.count == filteredContacts.count {
                                        selectedContactIds.removeAll()
                                    } else {
                                        selectedContactIds = Set(filteredContacts.map { $0.id ?? "" })
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: selectedContactIds.count == filteredContacts.count ? "checkmark.square.fill" : "square")
                                            .foregroundColor(AppColors.bodyPrimaryText)
                                        Text(selectedContactIds.count == filteredContacts.count ? "Deselect All" : "Select All")
                                            .font(.footnote)
                                            .foregroundColor(AppColors.bodyPrimaryText)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(selectedContactIds.count) selected")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                
                                if !selectedContactIds.isEmpty {
                                    Button(action: { showingBulkActionSheet = true }) {
                                        HStack(spacing: 8) {
                                            Text("Actions")
                                            Image("arrowdown")
                                                .renderingMode(.template)
                                        }
                                        .font(.footnote)
                                        .foregroundColor(AppColors.bodyPrimaryText)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(AppColors.cardGridBackground)
                                        .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.bottom, 12)
                    
                    // Contacts list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredContacts) { contact in
                                HStack {
                                    if isSelectionMode {
                                        Button(action: {
                                            if selectedContactIds.contains(contact.id ?? "") {
                                                selectedContactIds.remove(contact.id ?? "")
                                            } else {
                                                selectedContactIds.insert(contact.id ?? "")
                                            }
                                        }) {
                                            Image(systemName: selectedContactIds.contains(contact.id ?? "") ? "checkmark.square.fill" : "square")
                                                .foregroundColor(AppColors.bodyPrimaryText)
                                        }
                                    }
                                    
                                    ContactItemView(contact: Binding(
                                        get: { contact },
                                        set: { newValue in
                                            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                                                contacts[index] = newValue
                                            }
                                        }
                                    ))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView(isPro: $isPro)
            }
            .sheet(isPresented: $isShowingContactCreationEntry) {
                ContactCreationEntryView(isPresented: $isShowingContactCreationEntry)
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagerView()
            }
            .sheet(isPresented: $showUpgradeModal) {
                UpgradeModalView(isPresented: $showUpgradeModal)
            }
        }
        .actionSheet(isPresented: $showingBulkActionSheet) {
            ActionSheet(title: Text("Bulk Actions"),
                       message: Text("Choose an action for selected contacts"),
                       buttons: [
                           .default(Text("Add/Change Tags")) { showingBulkTagSheet = true },
                           .default(Text("Export as CSV")) { showingExportEmailSheet = true },
                           .destructive(Text("Delete")) { showingBulkDeleteConfirmation = true },
                           .cancel()
                       ])
        }
        .alert("Delete Contacts", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteSelectedContacts() }
        } message: {
            Text("Are you sure you want to delete \(selectedContactIds.count) contacts? This action cannot be undone.")
        }
        .sheet(isPresented: $showingBulkTagSheet) {
            BulkTagView(selectedContactIds: selectedContactIds) {
                isSelectionMode = false
                selectedContactIds.removeAll()
            }
        }
        .sheet(isPresented: $showingExportEmailSheet) {
            ExportContactsView(selectedContactIds: selectedContactIds) {
                isSelectionMode = false
                selectedContactIds.removeAll()
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
    
    private func deleteSelectedContacts() {
        Task {
            do {
                for contactId in selectedContactIds {
                    if let contact = contacts.first(where: { $0.id == contactId }) {
                        try await Contact.delete(contact)
                    }
                }
                selectedContactIds.removeAll()
                isSelectionMode = false
            } catch {
                print("Error deleting contacts: \(error)")
            }
        }
    }
}