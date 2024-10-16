//
//  WebLinksView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct WebLinksView: View {
    @Binding var businessCard: BusinessCard
    @State private var linkInputs: [WebLink] = []
    @FocusState private var focusedField: Field?
    var showHeader: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }
    
    enum Field: Hashable {
        case url(Int)
        case displayText(Int)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Web Links")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            ForEach(linkInputs.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    VStack(spacing: 10) {
                        CustomTextField(title: "Link", text: $linkInputs[index].url, onCommit: { focusedField = .displayText(index) })
                            .focused($focusedField, equals: .url(index))
                            .animation(.none, value: linkInputs[index].url)
                        CustomTextField(title: "Display Text (optional)", text: $linkInputs[index].displayText, onCommit: {
                            if index < linkInputs.count - 1 {
                                focusedField = .url(index + 1)
                            } else {
                                focusedField = nil
                            }
                        })
                        .focused($focusedField, equals: .displayText(index))
                        .animation(.none, value: linkInputs[index].displayText)
                    }
                    .layoutPriority(1)
                    
                    Button(action: { removeLink(at: index) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.top, 15)
                    }
                }
                
                Divider()
                    .padding(.top, 10)
            }
            
            Button(action: addNewLinkInput) {
                Text("Add Another Link")
                    .foregroundColor(AppColors.buttonText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.buttonBackground)
                    .cornerRadius(20)
            }
        }
        .padding(.top, showHeader ? 0 : 16)
        .animation(.none)
        .onAppear(perform: loadExistingLinks)
        .onChange(of: linkInputs) { _ in
            updateBusinessCard()
        }
    }
    
    private func loadExistingLinks() {
        linkInputs = businessCard.webLinks ?? []
        if linkInputs.isEmpty {
            linkInputs.append(WebLink(url: "", displayText: ""))
        }
    }
    
    private func addNewLinkInput() {
        linkInputs.append(WebLink(url: "", displayText: ""))
        focusedField = .url(linkInputs.count - 1)
    }
    
    private func removeLink(at index: Int) {
        linkInputs.remove(at: index)
        updateBusinessCard()
    }
    
    private func updateBusinessCard() {
        businessCard.webLinks = linkInputs.filter { !$0.url.isEmpty }
    }
}
