import SwiftUI

//
//  AddCardButton.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//

struct AddCardButton: View {
    var action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                    .font(.title2)
                Text("Create New Card")
                    .font(.headline)
            }
            .foregroundColor(foregroundColor)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardGridBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: 0xe5e6ed), lineWidth: 1)
                .opacity(colorScheme == .dark ? 1 : 0)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var foregroundColor: Color {
        colorScheme == .dark ? Color(hex: 0xdddee3) : Color.black
    }
}
