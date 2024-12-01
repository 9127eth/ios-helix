//
//  KeyboardDismissModifier.swift
//  Helix
//
//  Created by Richard Waithe on 10/13/24.
//

import SwiftUI

struct DismissKeyboardOnTapModifier: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.background(DismissKeyboardOnTapModifier())
    }
}