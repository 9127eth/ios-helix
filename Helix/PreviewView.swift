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
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            VStack {
                Text("Preview")
                    .font(.headline)
                    .padding()
                
                SafariView(url: URL(string: card.getCardURL())!)
                    .edgesIgnoringSafeArea(.all)
            }
            .background(Color.white)
            .cornerRadius(10)
            .padding()
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}
