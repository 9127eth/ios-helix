//
//  AddSocialLinkView.swift
//  Helix
//
//  Created by Richard Waithe on 10/13/24.
//

import SwiftUI

struct AddSocialLinkView: View {
    @Binding var availableLinks: [SocialLinkType]
    @Binding var businessCard: BusinessCard
    @Binding var isPresented: Bool
    @State private var selectedLink: SocialLinkType?
    @State private var linkValue: String = ""

    var body: some View {
        NavigationView {
            Form {
                Picker("Select Social Link", selection: $selectedLink) {
                    ForEach(availableLinks, id: \.self) { linkType in
                        Text(linkType.displayName).tag(Optional(linkType))
                    }
                }

                if let selected = selectedLink {
                    TextField(selected.displayName, text: $linkValue)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }
            }
            .navigationTitle("Add Social Link")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Add") {
                    addSocialLink()
                }
                .disabled(selectedLink == nil || linkValue.isEmpty)
            )
        }
    }

    private func addSocialLink() {
        guard let selected = selectedLink else { return }
        businessCard.setSocialLinkValue(for: selected, value: linkValue)
        if let index = availableLinks.firstIndex(of: selected) {
            availableLinks.remove(at: index)
        }
        isPresented = false
    }
}
