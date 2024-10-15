//
//  EditBusinessCardView.swift
//  Helix
//
//  Created by Richard Waithe on 10/14/24.
//

import SwiftUI
import FirebaseFirestore

struct EditBusinessCardView: View {
    @Binding var businessCard: BusinessCard
    @State private var editedCard: BusinessCard
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCancelConfirmation = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var expandedSections: Set<String> = []
    
    let sections = ["Description", "Basic Information", "Professional Information", "Contact Information", "Social Links", "Web Links", "Profile Image", "Custom Header/Message", "Document"]
    
    var body: some View {
        NavigationView {
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
                        }
                    }
                }
                .padding()
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
                    Button("Save") {
                        saveChanges()
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
            // Implement this view if it exists
            return AnyView(EmptyView())
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
    
    init(businessCard: Binding<BusinessCard>) {
        self._businessCard = businessCard
        self._editedCard = State(initialValue: businessCard.wrappedValue)
    }
}
