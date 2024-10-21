//
//  AddSocialLinkView.swift
//  Helix
//
//  Created by Richard Waithe on 10/13/24.
//

import SwiftUI

struct AddSocialLinkView: View {
    @Binding var availableLinks: [SocialLinkType]
    @Binding var selectedLinks: Set<SocialLinkType>
    @Binding var isPresented: Bool
    @State private var newlySelectedLinks: Set<SocialLinkType> = []
    var onLinksUpdated: () -> Void  // Add this line

    var body: some View {
        NavigationView {
            List {
                ForEach(SocialLinkType.allCases, id: \.self) { linkType in
                    Button(action: {
                        toggleLink(linkType)
                    }) {
                        HStack {
                            Image(linkType.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Text(linkType.displayName)
                            Spacer()
                            if isLinkSelected(linkType) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .disabled(!availableLinks.contains(linkType) && !selectedLinks.contains(linkType))
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Add Social Links")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Add") {
                    selectedLinks.formUnion(newlySelectedLinks)
                    onLinksUpdated()  // Call this function
                    isPresented = false
                }
            )
        }
        .onAppear {
            newlySelectedLinks = selectedLinks
        }
    }

    private func toggleLink(_ linkType: SocialLinkType) {
        if newlySelectedLinks.contains(linkType) {
            newlySelectedLinks.remove(linkType)
        } else {
            newlySelectedLinks.insert(linkType)
        }
    }

    private func isLinkSelected(_ linkType: SocialLinkType) -> Bool {
        newlySelectedLinks.contains(linkType)
    }
}
