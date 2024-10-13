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
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

struct CustomTextEditor: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            TextEditor(text: $text)
                .frame(height: 100)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}
