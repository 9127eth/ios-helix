//
//  ContentView.swift
//  Helix
//
//  Created by Richard Waithe on 10/8/24.
//

import SwiftUI
import SwiftData
import FirebaseFirestore

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var businessCards: [BusinessCard] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var hasAppeared = false
    @State private var showCreateCard = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                authenticatedView
            } else {
                AuthenticationView()
            }
        }
        .background(AppColors.background)
        .environmentObject(authManager)
    }
    
    private var authenticatedView: some View {
        TabView(selection: $selectedTab) {
            businessCardTab
            settingsTab
        }
        .fullScreenCover(isPresented: $showCreateCard) {
            CreateBusinessCardView(showCreateCard: $showCreateCard)
        }
        .onAppear(perform: fetchBusinessCards)
        .onChange(of: showCreateCard) { newValue in
            if !newValue {
                fetchBusinessCards()
            }
        }
        .overlay(loadingOverlay)
    }
    
    private var businessCardTab: some View {
        BusinessCardGridView(businessCards: $businessCards, showCreateCard: $showCreateCard)
            .tabItem {
                Image(systemName: "rectangle.on.rectangle")
                Text("Cards")
            }
            .tag(0)
    }
    
    private var settingsTab: some View {
        SettingsView()
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(1)
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    private func fetchBusinessCards() {
        guard let userId = authManager.currentUser?.uid else {
            print("Error: No authenticated user found")
            errorMessage = "User not authenticated"
            return
        }
        
        print("Fetching business cards for user: \(userId)")
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("businessCards").getDocuments { (querySnapshot, error) in
            isLoading = false
            
            if let error = error {
                print("Error getting documents: \(error)")
                errorMessage = "Failed to fetch business cards: \(error.localizedDescription)"
            } else {
                print("Query successful. Number of documents: \(querySnapshot?.documents.count ?? 0)")
                
                self.businessCards = querySnapshot?.documents.compactMap { document in
                    do {
                        var card = try document.data(as: BusinessCard.self)
                        card.id = document.documentID
                        print("Successfully decoded card: \(card.id ?? "Unknown ID")")
                        return card
                    } catch {
                        print("Error decoding document \(document.documentID): \(error)")
                        return nil
                    }
                } ?? []
                
                print("Fetched \(self.businessCards.count) business cards")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
