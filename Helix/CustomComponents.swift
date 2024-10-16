//
//  CustomComponents.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var onCommit: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            TextField("", text: $text, onCommit: {
                onCommit?()
            })
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppColors.inputFieldBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

struct CustomTextEditor: View {
    let title: String
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            TextEditor(text: $text)
                .frame(height: 100)
                .padding(8)
                .scrollContentBackground(.hidden) // Hide the default background
                .background(AppColors.inputFieldBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
    }
}
