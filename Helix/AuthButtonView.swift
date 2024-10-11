import SwiftUI

//
//  AuthButtonView.swift
//  Helix
//
//  Created by Richard Waithe on 10/10/24.
//
struct AuthButtonView: View {
    let image: String
    let text: String
    var isSystemImage: Bool = false
    
    var body: some View {
        HStack {
            if isSystemImage {
                Image(systemName: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)  // Changed from 24x24 to 20x20
            } else {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            }
            Text(text)
                .fontWeight(.medium)
        }
        .frame(width: 280, height: 50)
        .background(Color.white)
        .foregroundColor(.black)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(25)
    }
}
