//
//  BusinessCardItemView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI

struct BusinessCardItemView: View {
    var card: BusinessCard
    @State private var showPreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(card.description)
                    .font(.system(size: 38)) // Increased font size
                    .fontWeight(.bold)
                    .lineLimit(2) // Allow up to 2 lines
                    .minimumScaleFactor(0.5) // Scale down if needed
                    .foregroundColor(AppColors.bodyPrimaryText)
                
                Spacer()
                
                Menu {
                    Button("Preview") { showPreview = true }
                    Button("Share") { /* TODO: Implement share action */ }
                    Button("Edit") { /* TODO: Implement edit action */ }
                    Button("Delete", role: .destructive) { /* TODO: Implement delete action */ }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppColors.bodyPrimaryText)
                        .padding(.top, 4)
                        .padding(.trailing, 4)
                }
            }
            
            if let jobTitle = card.jobTitle {
                Text(jobTitle)
                    .font(.subheadline)
                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                    .lineLimit(1)
            }
            
            if let company = card.company {
                Text(company)
                    .font(.subheadline)
                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack {
                HStack(spacing: 4) {
                    if card.isPrimary {
                        Text("Main")
                            .font(.caption)
                            .foregroundColor(Color.gray)
                    }
                    if !card.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(Color.gray)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) { // Increased spacing between buttons
                    Button(action: { /* TODO: Implement edit action */ }) {
                        Image(systemName: "square.and.pencil")
                            .frame(width: 30, height: 30) // Increased button size
                    }
                    Button(action: { /* TODO: Implement preview action */ }) {
                        Image(systemName: "magnifyingglass")
                            .frame(width: 30, height: 30)
                    }
                    Button(action: { /* TODO: Implement share action */ }) {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 30, height: 30) // Increased button size
                    }
                    .disabled(!card.isActive)
                }
                .foregroundColor(.black) // Changed to black
                .font(.system(size: 18)) // Increased icon size
            }
        }
        .padding()
        .frame(height: 180)
        .background(AppColors.cardGridBackground)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showPreview) {
            PreviewView(card: card, isPresented: $showPreview)
        }
    }
}
