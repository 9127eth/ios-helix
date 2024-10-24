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
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                    }
                    
                    LazyVStack(spacing: 16) {
                        ForEach(Array($businessCards.enumerated()), id: \.element.id) { index, $card in
                            BusinessCardItemView(card: $card, username: username)
                        }
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
                    Text("Get Helix Pro")
                        .font(.subheadline)
                        .foregroundColor(AppColors.helixPro)
                }
                .padding(.bottom, 5)
            }
            
            Text("Business Cards")
                .font(.system(size: 60, weight: .bold)) // Increased font size
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                Image("calendar")
                    .foregroundColor(.gray)
                Text("It's \(formattedDate())")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
        .padding(.bottom, 10)
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
