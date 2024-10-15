//
//  BusinessCardItemView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI

struct BusinessCardItemView: View {
    @Binding var card: BusinessCard
    @State private var showPreview = false
    @State private var showShare = false
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(card.description)
                    .font(.system(size: 38))
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(AppColors.bodyPrimaryText)
                
                Spacer()
                
                Menu {
                    Button("Preview") { showPreview = true }
                    Button("Share") { showShare = true }
                    Button("Edit") { showingEditView = true }
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
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
                
                HStack(spacing: 16) {
                    Button(action: { showingEditView = true }) {
                        Image(systemName: "square.and.pencil")
                            .frame(width: 30, height: 30)
                    }
                    Button(action: { showPreview = true }) {
                        Image(systemName: "magnifyingglass")
                            .frame(width: 30, height: 30)
                    }
                    Button(action: { showShare = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 30, height: 30)
                    }
                    .disabled(!card.isActive)
                }
                .foregroundColor(.black)
                .font(.system(size: 18))
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
        .sheet(isPresented: $showShare) {
            ShareView(card: card, isPresented: $showShare)
        }
        .sheet(isPresented: $showingEditView) {
            EditBusinessCardView(businessCard: $card)
        }
        .alert("Confirm Deletion", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCard()
            }
        } message: {
            Text("Are you sure you want to delete this business card? This action cannot be undone.")
        }
    }
    
    private func deleteCard() {
        Task {
            do {
                try await BusinessCard.delete(card)
                // Here you would typically update your app's state to remove the card from the list
                // This might involve notifying a parent view or using an environment object
                print("Card deleted successfully")
            } catch {
                print("Error deleting card: \(error.localizedDescription)")
                // Here you might want to show an error alert to the user
            }
        }
    }
}
