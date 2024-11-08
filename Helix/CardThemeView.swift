//
//  CardThemeView.swift
//  Helix
//
//  Created by Richard Waithe on 11/8/24.
//

import SwiftUI

struct CardThemeView: View {
    @Binding var businessCard: BusinessCard
    var showHeader: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showHeader {
                Text("Card Theme")
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            VStack(spacing: 12) {
                ForEach(["classic", "modern", "dark"], id: \.self) { theme in
                    ThemeButton(
                        theme: theme,
                        isSelected: businessCard.theme == theme,
                        action: { businessCard.theme = theme }
                    )
                }
            }
        }
        .padding(.top, showHeader ? 0 : 16)
    }
}

struct ThemeButton: View {
    let theme: String
    let isSelected: Bool
    let action: () -> Void
    
    var themeTitle: String {
        switch theme {
        case "classic": return "Classic"
        case "modern": return "Modern"
        case "dark": return "Dark Mode"
        default: return ""
        }
    }
    
    var themeDescription: String {
        switch theme {
        case "classic": return "Traditional black and white theme"
        case "modern": return "A modern look with blue-green accents"
        case "dark": return "Dark colors with shades of black and gray"
        default: return ""
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(themeTitle)
                        .font(.system(size: 16, weight: .medium))
                    Text(themeDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(AppColors.inputFieldBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

