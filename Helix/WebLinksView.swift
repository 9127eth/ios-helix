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
    
    enum Field: Hashable {
        case url(Int)
        case displayText(Int)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Web Links")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(businessCard.webLinks ?? [], id: \.id) { link in
                VStack {
                    HStack {
                        Text(link.displayText)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Text(link.url)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    Divider()
                }
            }
            
            ForEach(linkInputs.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    VStack(spacing: 10) {
                        CustomTextField(title: "Link", text: $linkInputs[index].url, onCommit: { focusedField = .displayText(index) })
                            .focused($focusedField, equals: .url(index))
                        CustomTextField(title: "Display Text (optional)", text: $linkInputs[index].displayText, onCommit: {
                            if index < linkInputs.count - 1 {
                                focusedField = .url(index + 1)
                            } else {
                                focusedField = nil
                            }
                        })
                        .focused($focusedField, equals: .displayText(index))
                    }
                    
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.primary)
                    .cornerRadius(20)
            }
        }
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
