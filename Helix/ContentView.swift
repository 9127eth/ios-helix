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
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init() {
        setupNavigationBarAppearance()
        setupTabBarAppearance()
    }
    
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.barMenuBackground)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.bodyPrimaryText)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.bodyPrimaryText)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.barMenuBackground)
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                authenticatedView
            } else {
                AuthenticationView()
            }
        }
        .background(AppColors.background)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environmentObject(authManager)
    }
    
    private var authenticatedView: some View {
        TabView(selection: $selectedTab) {
            businessCardTab
            settingsTab
        }
        .accentColor(AppColors.primary) // This sets the selected tab color
        .onAppear {
            UITabBar.appearance().unselectedItemTintColor = UIColor(AppColors.bodyPrimaryText)
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
        .onAppear {
            selectedTab = 0
        }
    }
    
    private var businessCardTab: some View {
        BusinessCardGridView(businessCards: $businessCards, showCreateCard: $showCreateCard, username: username)
            .tabItem {
                VStack {
                    Image(systemName: "rectangle.on.rectangle")
                        .padding(.top, 8)
                    Text("Cards")
                }
            }
            .tag(0)
    }
    
    private var settingsTab: some View {
        SettingsView(isAuthenticated: $authManager.isAuthenticated)
            .tabItem {
                VStack {
                    Image(systemName: "gear")
                        .padding(.top, 8)
                    Text("Settings")
                }
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
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.barMenuBackground)
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.bodyPrimaryText.opacity(0.6))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(AppColors.bodyPrimaryText.opacity(0.6))]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppColors.primary)]

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
