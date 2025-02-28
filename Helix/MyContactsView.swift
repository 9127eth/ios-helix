//
//  MyContactsView.swift
//  Helix
//
//  Created by Richard Waithe on 11/30/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

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
    @State private var showProTip = true
    
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
                        
                        // Only show the Create New button if there's at least one contact
                        if !contacts.isEmpty {
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
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    
                    // Pro Tip banner (visible when there's at least one contact and showProTip is true)
                    if !contacts.isEmpty && showProTip {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(AppColors.helixPro)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pro Tip")
                                    .font(.headline)
                                    .foregroundColor(AppColors.bodyPrimaryText)
                                
                                Text("Use tags to organize your contacts and optimize bulk exports to your CRM system.")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    showProTip = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.6))
                                    .padding(8)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.10))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut, value: !contacts.isEmpty)
                    }
                    
                    // Search and filters with Select button
                    VStack(spacing: 12) {
                        if !contacts.isEmpty {
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
                    }
                    .padding(.bottom, 12)
                    
                    // Contacts list
                    ScrollView {
                        if contacts.isEmpty {
                            // Empty state view
                            VStack(spacing: 24) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(AppColors.helixPro)
                                    .padding(.bottom, 8)
                                
                                Text("Your Contacts List is Empty")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.bodyPrimaryText)
                                
                                Text("This is where you'll see all your networking connections. Add contacts manually or use our AI scanning tool on your mobile device to quickly capture business cards and contact information.")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    if !isPro && contacts.count >= 2 {
                                        showUpgradeModal = true
                                    } else {
                                        isShowingContactCreationEntry = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Your First Contact")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColors.cardDepthDefault)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }
                                .padding(.horizontal, 40)
                                .padding(.top, 8)
                                
                                if !isPro {
                                    Divider()
                                        .padding(.vertical, 16)
                                    
                                    Text("Unlock AI-Powered Networking")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.bodyPrimaryText)
                                        .padding(.bottom, 8)
                                    
                                    // Feature cards
                                    ForEach(proFeatures) { feature in
                                        HStack(spacing: 16) {
                                            Image(feature.icon)
                                                .renderingMode(.template)
                                                .foregroundColor(AppColors.helixPro)
                                                .frame(width: 24, height: 24)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(feature.title)
                                                    .font(.headline)
                                                    .foregroundColor(AppColors.bodyPrimaryText)
                                                
                                                Text(feature.description)
                                                    .font(.subheadline)
                                                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.10))
                                        .cornerRadius(16)
                                    }
                                    
                                    Button(action: {
                                        showSubscriptionView = true
                                    }) {
                                        HStack {
                                            Image(systemName: "bolt.fill")
                                            Text("Upgrade to Helix Pro")
                                        }
                                        .font(.headline)
                                        .foregroundColor(AppColors.buttonText)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.buttonBackground)
                                        .cornerRadius(16)
                                    }
                                    .padding(.top, 16)
                                }
                            }
                            .padding(.vertical, 40)
                            .padding(.horizontal)
                        }
                        
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
                        
                        // Add the new promotional content
                        if !isPro && !contacts.isEmpty {
                            VStack(spacing: 24) {
                                // Add this new title section
                                Text("Unlock AI-Powered Networking")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.bodyPrimaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 8)
                                
                                // Existing feature cards
                                ForEach(proFeatures) { feature in
                                    HStack(spacing: 16) {
                                        Image(feature.icon)
                                            .renderingMode(.template)
                                            .foregroundColor(AppColors.helixPro)
                                            .frame(width: 24, height: 24)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(feature.title)
                                                .font(.headline)
                                                .foregroundColor(AppColors.bodyPrimaryText)
                                            
                                            Text(feature.description)
                                                .font(.subheadline)
                                                .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.10))
                                    .cornerRadius(16)
                                }
                                
                                // Add this new text
                                Text("Try it now by hitting the Create New button at the top of this page. You can create 2 contacts to see how it works before upgrading.")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                
                                // Existing upgrade button
                                Button(action: {
                                    showSubscriptionView = true
                                }) {
                                    HStack {
                                        Image(systemName: "bolt.fill")
                                        Text("Upgrade to Helix Pro")
                                    }
                                    .font(.headline)
                                    .foregroundColor(AppColors.buttonText)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColors.buttonBackground)
                                    .cornerRadius(16)
                                }
                            }
                            .padding()
                        }
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
            // Reset Pro Tip visibility when the view appears
            if !contacts.isEmpty {
                showProTip = true
            }
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
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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

extension MyContactsView {
    var proFeatures: [ProFeature] {
        [
            ProFeature(
                icon: "ai",
                title: "AI-Powered Scanning",
                description: "Quickly scan business cards with our advanced AI and vision technology."
            ),
            ProFeature(
                icon: "savecontact",
                title: "Contacts Always at Your Fingertips",
                description: "Your scanned contacts are always at your fingertips. Never lose a contact again."
            ),
            ProFeature(
                icon: "download",
                title: "Simple Export",
                description: "Easily export your contacts. They'll be ready to import into your favorite CRM."
            ),
            ProFeature(
                icon: "lock",
                title: "Secure Storage",
                description: "Your contacts are securely stored and protected."
            )
        ]
    }
}