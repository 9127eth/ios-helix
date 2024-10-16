//
//  PreviewView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//

import SwiftUI
import SafariServices

struct PreviewView: View {
    let card: BusinessCard
    let username: String
    @Binding var isPresented: Bool
    
    var body: some View {
        SafariView(url: URL(string: card.getCardURL(username: username))!)
            .edgesIgnoringSafeArea(.all)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}
