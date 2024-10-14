import SwiftUI

//
//  AddCardButton.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//

struct AddCardButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: "plus.circle")
                    .font(.largeTitle)
                Text("Create New Card")
                    .font(.headline)
            }
            .foregroundColor(AppColors.primary)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardGridBackground)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
