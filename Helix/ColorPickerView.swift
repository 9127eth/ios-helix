//
//  ColorPickerView.swift
//  Helix
//
//  Created by Richard Waithe on 10/25/24.
//

import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Binding var card: BusinessCard
    @Environment(\.dismiss) var dismiss
    
    // Predefined colors
    let predefinedColors: [(name: String, color: Color)] = [
        ("Default", AppColors.cardDepthDefault),
        ("Green", Color(red: 184/255, green: 235/255, blue: 65/255)),
        ("Brown", Color(red: 252/255, green: 154/255, blue: 153/255)),
        ("Beige", Color(red: 225/255, green: 219/255, blue: 198/255))
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Predefined colors
                VStack(alignment: .leading) {
                    Text("Presets")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        ForEach(predefinedColors, id: \.name) { colorOption in
                            ColorButton(color: colorOption.color,
                                      isSelected: selectedColor == colorOption.color) {
                                selectedColor = colorOption.color
                            }
                        }
                    }
                }
                
                Divider()
                
                // Custom color picker
                VStack(alignment: .leading) {
                    Text("Custom Color")
                        .font(.headline)
                    ColorPicker("Select a custom color", selection: $selectedColor)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Card Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveColor()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveColor() {
        Task {
            do {
                var updatedCard = card
                updatedCard.cardDepthColor = selectedColor.toHex()
                try await BusinessCard.saveChanges(updatedCard)
                card = updatedCard
            } catch {
                print("Error saving color: \(error)")
            }
        }
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.primary, lineWidth: isSelected ? 2 : 0)
                )
        }
    }
}
