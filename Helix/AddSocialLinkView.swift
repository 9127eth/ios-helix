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

    var body: some View {
        NavigationView {
            List {
                ForEach(availableLinks, id: \.self) { linkType in
                    Button(action: {
                        if selectedLinks.contains(linkType) {
                            selectedLinks.remove(linkType)
                        } else {
                            selectedLinks.insert(linkType)
                        }
                    }) {
                        HStack {
                            Image(linkType.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Text(linkType.displayName)
                            Spacer()
                            if selectedLinks.contains(linkType) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Add Social Links")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Add") {
                    isPresented = false
                }
                .disabled(selectedLinks.isEmpty)
            )
        }
    }
}
