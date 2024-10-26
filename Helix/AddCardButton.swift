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
        ZStack {
            // Background shadow layer for depth effect
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.5))
                .offset(x: 8, y: 8)
            
            // Main button content
            Button(action: action) {
                HStack {
                    Image("addNewCard")
                        .renderingMode(.template)
                    Text("Create New Card")
                        .font(.headline)
                }
                .foregroundColor(foregroundColor)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(AppColors.cardGridBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: 0xe5e6ed), lineWidth: 1)
                    .opacity(colorScheme == .dark ? 1 : 0)
            )
        }
        .frame(height: 200)
    }
    
    private var foregroundColor: Color {
        colorScheme == .dark ? Color(hex: 0xdddee3) : Color.black
    }
}
