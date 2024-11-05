//
//  KeyboardAvoidingView.swift
//  Helix
//
//  Created by Richard Waithe on 10/13/24.
//

import SwiftUI

struct KeyboardAvoidingView<Content: View>: View {
    @State private var keyboardHeight: CGFloat = 0
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, max(keyboardHeight - geometry.safeAreaInsets.bottom, 0))
                .animation(.easeOut(duration: 0.16), value: keyboardHeight)
                .dismissKeyboardOnTap()
                .onAppear {
                    setupKeyboardObservers(geometry: geometry)
                }
        }
    }

    private func setupKeyboardObservers(geometry: GeometryProxy) {
        let safeAreaInsets = geometry.safeAreaInsets.bottom
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let keyboardHeight = keyboardFrame.height - safeAreaInsets
            self.keyboardHeight = max(0, keyboardHeight)
            print("Keyboard shown, height: \(self.keyboardHeight)")
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.keyboardHeight = 0
            print("Keyboard hidden")
        }
    }
}
