//
//  BusinessCardItemView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import NotificationCenter

struct BusinessCardItemView: View {
    @Binding var card: BusinessCard
    let username: String
    @State private var showPreview = false
    @State private var showShare = false
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    @State private var offset: CGFloat = 0
    @State private var showingActionButtons = false
    @State private var actionButtonsOpacity: Double = 0 // Add this line
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Spacer()
                    actionButtons
                        .frame(width: 220, height: geometry.size.height)
                        .offset(x: offset + 220)
                        .opacity(actionButtonsOpacity) // Add this line
                }
                .frame(height: geometry.size.height, alignment: .center)
            }
            
            cardContent
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { gesture in
                            if abs(gesture.translation.width) > abs(gesture.translation.height) {
                                offset = min(0, gesture.translation.width)
                                // Gradually increase opacity as user swipes
                                actionButtonsOpacity = Double(-offset / 220)
                            }
                        }
                        .onEnded { gesture in
                            withAnimation {
                                if gesture.translation.width < -50 && abs(gesture.translation.width) > abs(gesture.translation.height) {
                                    offset = -220
                                    showingActionButtons = true
                                    actionButtonsOpacity = 1 // Fully visible
                                } else {
                                    offset = 0
                                    showingActionButtons = false
                                    actionButtonsOpacity = 0 // Fully hidden
                                }
                            }
                        }
                )
        }
        .sheet(isPresented: $showPreview) {
            PreviewView(card: card, username: username, isPresented: $showPreview)
        }
        .sheet(isPresented: $showShare) {
            ShareView(card: card, username: username, isPresented: $showShare)
        }
        .sheet(isPresented: $showingEditView) {
            EditBusinessCardView(businessCard: $card, username: username)
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
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                actionButton(title: "Share", action: { showShare = true })
                actionButton(title: "Preview", action: { showPreview = true })
            }
            HStack(spacing: 20) {
                actionButton(title: "Edit", action: { showingEditView = true })
                actionButton(title: "Delete", action: { showingDeleteConfirmation = true })
            }
        }
    }
    
    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.buttonText)
                .frame(width: 90, height: 40)
                .background(AppColors.buttonBackground)
                .cornerRadius(12)
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(card.description)
                    .font(.system(size: 30))  // Fixed font size
                    .fontWeight(.bold)
                    .lineLimit(1)  // Limit to one line
                    .truncationMode(.tail)  // Add ellipsis at the end
                    .foregroundColor(AppColors.bodyPrimaryText)
                    .onTapGesture {
                        if card.isActive {
                            showShare = true
                        }
                    }
                
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
                .background(AppColors.divider)
            
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
                .foregroundColor(colorScheme == .dark ? Color(hex: 0xdddee3) : .black)
                .font(.system(size: 18))
            }
        }
        .padding()
        .frame(height: 200)
        .background(AppColors.cardGridBackground)
        .cornerRadius(20) // Increased from 8 to 20
        .overlay(
            RoundedRectangle(cornerRadius: 20) // Increased from 8 to 20
                .stroke(Color(hex: 0xe5e6ed), lineWidth: 1)
                .opacity(colorScheme == .dark ? 1 : 0)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func deleteCard() {
        Task {
            do {
                try await BusinessCard.delete(card)
                print("Card deleted successfully")
                // Notify the parent view that a card was deleted
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .cardDeleted, object: nil)
                }
            } catch {
                print("Error deleting card: \(error.localizedDescription)")
                // Here you might want to show an error alert to the user
            }
        }
    }
}
