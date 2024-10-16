//
//  ContentView.swift
//  Helix
//
//  Created by Richard Waithe on 10/8/24.
//

import SwiftUI
import SwiftData
import FirebaseFirestore
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var businessCards: [BusinessCard] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var hasAppeared = false
    @State private var showCreateCard = false
    @State private var username: String = ""
    
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
        .onReceive(NotificationCenter.default.publisher(for: .cardDeleted)) { _ in
            fetchBusinessCards()
        }
    }
    
    private var businessCardTab: some View {
        BusinessCardGridView(businessCards: $businessCards, showCreateCard: $showCreateCard, username: username)
            .tabItem {
                Image(systemName: "rectangle.on.rectangle")
                Text("Cards")
            }
            .tag(0)
    }
    
    private var settingsTab: some View {
        SettingsView(isAuthenticated: $authManager.isAuthenticated)
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
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            errorMessage = "User not authenticated"
            return
        }
        isLoading = true
        print("Fetching business cards for user: \(userId)")
        errorMessage = nil
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        Task {
            do {
                let userDocument = try await userRef.getDocument()
                guard let userData = userDocument.data(),
                      let fetchedUsername = userData["username"] as? String else {
                    throw NSError(domain: "com.yourapp.error", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user data"])
                }
                
                self.username = fetchedUsername
                
                let querySnapshot = try await userRef.collection("businessCards").getDocuments()
                self.businessCards = querySnapshot.documents.compactMap { document in
                    do {
                        var card = try document.data(as: BusinessCard.self)
                        card.id = document.documentID
                        return card
                    } catch {
                        print("Error decoding document \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                isLoading = false
            } catch {
                print("Error fetching business cards: \(error)")
                errorMessage = "Failed to fetch business cards: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
