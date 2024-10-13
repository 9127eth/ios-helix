//
//  WebLinksView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct WebLinksView: View {
    @Binding var businessCard: BusinessCard
    @State private var linkInputs: [(url: String, displayText: String)] = [(url: "", displayText: "")]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Web Links")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(businessCard.webLinks ?? [], id: \.url) { link in
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
                        CustomTextField(title: "Link", text: $linkInputs[index].url)
                        CustomTextField(title: "Display Text (optional)", text: $linkInputs[index].displayText)
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
    }
    
    private func addNewLinkInput() {
        linkInputs.append((url: "", displayText: ""))
    }
    
    private func removeLink(at index: Int) {
        linkInputs.remove(at: index)
    }
}
