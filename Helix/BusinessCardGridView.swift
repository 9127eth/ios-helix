//
//  BusinessCardView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth  // Add this line

struct BusinessCardGridView: View {
    @Binding var businessCards: [BusinessCard]
    @Binding var showCreateCard: Bool
    let username: String
    @Binding var isPro: Bool
    @State private var showSubscriptionView = false
    @State private var showUpgradeModal = false
    @State private var showMaxCardsAlert = false

    
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 10) {
                    headerView
                        .opacity(opacityForOffset(0))
                    
                    Spacer(minLength: UIScreen.main.bounds.height * 0.02)
                    
                    // Only show the "Create New" button if there are cards
                    if !businessCards.isEmpty {
                        HStack {
                            Spacer()
                            Button(action: {
                                if businessCards.count >= 10 {
                                    showMaxCardsAlert = true
                                } else if businessCards.count >= 1 && !isPro {
                                    showUpgradeModal = true
                                } else {
                                    showCreateCard = true
                                }
                            }) {
                                Label {
                                    Text("Create New")
                                        .font(.footnote)
                                } icon: {
                                    Image("addNewCard")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                }
                                .foregroundColor(AppColors.buttonText)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(AppColors.buttonBackground)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                    }
                    
                    LazyVStack(spacing: 16) {
                        if businessCards.isEmpty {
                            welcomeView
                        }
                        
                        ForEach(Array($businessCards.enumerated()), id: \.element.id) { index, $card in
                            BusinessCardItemView(card: $card, username: username)
                        }
                        
                        // Only show the AddCardButton when there are already cards
                        if !businessCards.isEmpty {
                            AddCardButton(action: {
                                if businessCards.count >= 10 {
                                    showMaxCardsAlert = true
                                } else if businessCards.count >= 1 && !isPro {
                                    showUpgradeModal = true
                                } else {
                                    showCreateCard = true
                                }
                            })
                        }
                    }
                }
                .padding()
                .background(GeometryReader { proxy -> Color in
                    DispatchQueue.main.async {
                        scrollOffset = -proxy.frame(in: .named("scroll")).origin.y
                    }
                    return Color.clear
                })
            }
            .coordinateSpace(name: "scroll")
            .background(AppColors.background)
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView(isPro: $isPro)
            }
            .sheet(isPresented: $showUpgradeModal) {
                UpgradeModalView(isPresented: $showUpgradeModal)
            }
            .alert(isPresented: $showMaxCardsAlert) {
                Alert(
                    title: Text("Maximum Cards Reached"),
                    message: Text("You have reached the maximum limit of 10 cards. Please contact support to increase your limit."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                fetchUserProStatus()
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !isPro {
                Button(action: {
                    showSubscriptionView = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)
                        Text("Get Helix Pro")
                            .font(.subheadline)
                    }
                    .foregroundColor(AppColors.helixPro)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.10))  // Increased from 0.15 to 0.25 for darker gray
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)  // Added subtle shadow
                }
                .padding(.bottom, 5)
            }
            
            Text("Business Cards")
                .font(.system(size: 60, weight: .bold))
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                Image("calendar")
                    .foregroundColor(AppColors.cardDepthDefault)
                Text("It's \(formattedDate())")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
        .padding(.bottom, 10)
    }
    
    private var welcomeView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to Helix! 🎉")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.bodyPrimaryText)
            
            Text("We're excited to have you join us on this journey!")
                .font(.headline)
                .foregroundColor(AppColors.bodyPrimaryText)
            
            VStack(alignment: .leading, spacing: 16) {
                featureItem(
                    icon: "wand.and.stars",
                    title: "Create Your Digital Business Card",
                    description: "Start by creating your first digital business card. Customize it with your information, social links, and profile image."
                )
                
                featureItem(
                    icon: "wallet.pass",
                    title: "Add to Your Digital Wallet",
                    description: "Once created, you can add your card to Apple Wallet for easy access, or link it to an NFC device."
                )
                
                featureItem(
                    icon: "qrcode",
                    title: "Share Instantly",
                    description: "Share your digital card via QR code, link, or tap with compatible NFC devices."
                )
                
                featureItem(
                    icon: "brain",
                    title: "AI Scanning Tool",
                    description: "Use our AI scanning technology to quickly capture and save business cards as digital contacts in your network."
                )
            }
            .padding(.vertical, 10)
            
            Button(action: {
                showCreateCard = true
            }) {
                Text("Create Your First Card")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.buttonBackground)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardGridBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 24)
    }
    
    private func featureItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppColors.buttonBackground)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.bodyPrimaryText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.bodySecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func opacityForOffset(_ offset: CGFloat) -> Double {
        // For cards
        if offset > UIScreen.main.bounds.height * 0.3 {
            let startFadePoint = UIScreen.main.bounds.height * 0.4  // Point where fade begins
            let fadeDistance = UIScreen.main.bounds.height * 0.7    // Distance over which fade occurs
            
            let relativeOffset = scrollOffset - offset
            let opacity = 1.0 - Double(max(0, relativeOffset - startFadePoint)) / Double(fadeDistance)
            return max(0.2, min(1, opacity))
        }
        
        // For header and other elements (original behavior)
        let opacity = 1.0 - Double(max(0, scrollOffset - offset)) / 150.0
        return max(0, min(1, opacity))
    }
    
    private func fetchUserProStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                self.isPro = document.data()?["isPro"] as? Bool ?? false
            }
        }
    }
    
    private func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        return dateFormatter.string(from: Date())
    }
}
