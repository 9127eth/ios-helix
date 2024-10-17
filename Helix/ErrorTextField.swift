//
//  ErrorTextField.swift
//  Helix
//
//  Created by Richard Waithe on 10/17/24.
//

import SwiftUI

struct ErrorTextField: View {
    let title: String
    @Binding var text: String
    @Binding var showError: Bool
    var onCommit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading) {
            CustomTextField(title: title, text: $text, onCommit: onCommit)
                .onChange(of: text) { _ in
                    showError = false
                }
            if showError {
                Text("This field is required")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}
