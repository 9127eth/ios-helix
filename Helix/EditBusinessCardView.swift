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
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteConfirmation = false
    @State private var showingCancelConfirmation = false
    @State private var showingPreview = false
    @State private var expandedSections: Set<String> = []
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    
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
                            sectionContent(for: section)
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
        .alert(isPresented: $showingCancelConfirmation) {
            Alert(
                title: Text("Discard Changes?"),
                message: Text("Are you sure you want to discard your changes?"),
                primaryButton: .destructive(Text("Discard")) {
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showingSaveError) {
            Alert(
                title: Text("Error Saving Changes"),
                message: Text(saveErrorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func sectionContent(for section: String) -> some View {
        switch section {
        case "Description":
            return AnyView(DescriptionView(businessCard: $businessCard, showHeader: false))
        case "Basic Information":
            return AnyView(BasicInformationView(businessCard: $businessCard, showHeader: false))
        case "Professional Information":
            return AnyView(ProfessionalInformationView(businessCard: $businessCard, showHeader: false))
        case "Contact Information":
            return AnyView(ContactInformationView(businessCard: $businessCard, showHeader: false))
        case "Social Links":
            return AnyView(SocialLinksView(businessCard: $businessCard, showHeader: false))
        case "Web Links":
            return AnyView(WebLinksView(businessCard: $businessCard, showHeader: false))
        case "Profile Image":
            return AnyView(ProfileImageView(businessCard: $businessCard, showHeader: false))
        case "Custom Header/Message":
            // Implement this view if it exists
            return AnyView(EmptyView())
        case "Document":
            // Implement this view if it exists
            return AnyView(EmptyView())
        default:
            return AnyView(EmptyView())
        }
    }
    
    func saveChanges() {
        Task {
            do {
                try await BusinessCard.saveChanges(businessCard)
                presentationMode.wrappedValue.dismiss()
            } catch {
                saveErrorMessage = error.localizedDescription
                showingSaveError = true
            }
        }
    }
}