//
//  KeyboardDismissModifier.swift
//  Helix
//
//  Created by Richard Waithe on 10/13/24.
//

import SwiftUI

struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.modifier(KeyboardDismissModifier())
    }
}