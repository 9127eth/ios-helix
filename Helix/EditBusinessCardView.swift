//
//  EditBusinessCardView.swift
//  Helix
//
//  Created by Richard Waithe on 10/14/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import NotificationCenter

struct EditBusinessCardView: View {
    @Binding var businessCard: BusinessCard
    let username: String  // Add this line
    @State private var editedCard: BusinessCard
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCancelConfirmation = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var expandedSections: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var showPreview = false
    
    let sections = ["Description", "Basic Information", "Professional Information", "Contact Information", "Social Links", "Web Links", "Profile Image", "Custom Header/Message", "Document"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.editSheetBackground.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(sections, id: \.self) { section in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedSections.contains(section) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            expandedSections.insert(section)
                                        } else {
                                            expandedSections.remove(section)
                                        }
                                    }
                                )
                            ) {
                                sectionContent(for: section, card: $editedCard)
                                    .padding(.top, 16)
                            } label: {
                                Text(section)
                                    .font(.headline)
                                    .foregroundColor(AppColors.primaryText) // Add this line
                            }
                        }
                        
                        Divider()
                            .background(Color.gray)
                            .padding(.vertical)
                        
                        dangerSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCancelConfirmation = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showPreview = true }) {
                            Text("Preview")
                        }
                        Button("Save") {
                            saveChanges()
                        }
                    }
                }
            }
        }
        .alert("Confirm Cancel", isPresented: $showingCancelConfirmation) {
            Button("Continue Editing", role: .cancel) {}
            Button("Discard Changes", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel? Any unsaved changes will be lost.")
        }
        .alert(isPresented: $showingSaveError) {
            Alert(
                title: Text("Error Saving Changes"),
                message: Text(saveErrorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Confirm Deletion", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteBusinessCard()
            }
        } message: {
            Text("Are you sure you want to delete this business card? This action is irreversible.")
        }
        .sheet(isPresented: $showPreview) {
            PreviewView(card: editedCard, username: username, isPresented: $showPreview)
        }
    }
    
    private var dangerSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Danger!")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Text("Delete Card")
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.red)
                    .cornerRadius(6)
                    .font(.system(size: 14))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    func sectionContent(for section: String, card: Binding<BusinessCard>) -> some View {
        switch section {
        case "Description":
            return AnyView(DescriptionView(businessCard: card, showHeader: false))
        case "Basic Information":
            return AnyView(BasicInformationView(businessCard: card, showHeader: false))
        case "Professional Information":
            return AnyView(ProfessionalInformationView(businessCard: card, showHeader: false))
        case "Contact Information":
            return AnyView(ContactInformationView(businessCard: card, showHeader: false))
        case "Social Links":
            return AnyView(SocialLinksView(businessCard: card, showHeader: false))
        case "Web Links":
            return AnyView(WebLinksView(businessCard: card, showHeader: false))
        case "Profile Image":
            return AnyView(ProfileImageView(businessCard: card, showHeader: false))
        case "Custom Header/Message":
            return AnyView(CustomSectionView(businessCard: card, showHeader: false))
        case "Document":
            return AnyView(DocumentView(businessCard: card, showHeader: false))
        default:
            return AnyView(EmptyView())
        }
    }
    
    func saveChanges() {
        Task {
            do {
                try await BusinessCard.saveChanges(editedCard)
                businessCard = editedCard // Update the original card
                presentationMode.wrappedValue.dismiss()
            } catch {
                saveErrorMessage = error.localizedDescription
                showingSaveError = true
            }
        }
    }
    
    private func deleteBusinessCard() {
        Task {
            do {
                try await BusinessCard.delete(editedCard)
                print("Card deleted successfully")
                // Notify that a card was deleted
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .cardDeleted, object: nil)
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Error deleting card: \(error.localizedDescription)")
                // Here you might want to show an error alert to the user
            }
        }
    }
    
    init(businessCard: Binding<BusinessCard>, username: String) {
        self._businessCard = businessCard
        self._editedCard = State(initialValue: businessCard.wrappedValue)
        self.username = username
    }
}
