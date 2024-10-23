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
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var isPro: Bool = false
    
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
        .onAppear {
            configureTabBarAppearance()
            fetchUserProStatus()
            fetchBusinessCards()
        }
        .accentColor(AppColors.bottomNavIcon) // This sets the selected tab color
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
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
            self.businessCards = []
            self.username = ""
        }
        .onAppear {
            selectedTab = 0
        }
    }
    
    private var businessCardTab: some View {
        BusinessCardGridView(businessCards: $businessCards, showCreateCard: $showCreateCard, username: username, isPro: $isPro)
            .tabItem {
                Label {
                    Text("Cards")
                } icon: {
                    Image("cardsNavi")
                        .renderingMode(.template)
                }
            }
            .tag(0)
    }
    
    private var settingsTab: some View {
        SettingsView(isAuthenticated: $authManager.isAuthenticated)
            .tabItem {
                Label {
                    Text("Settings")
                } icon: {
                    Image("settingsNavi")
                        .renderingMode(.template)
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
            return
        }
        isLoading = true
        print("Fetching business cards for user: \(userId)")
        errorMessage = nil
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        Task {
            do {
                // Force fetch the latest user data from the server
                let userDocument = try await userRef.getDocument(source: .server)
                guard let userData = userDocument.data(),
                      let fetchedUsername = userData["username"] as? String else {
                    // New user without any data yet
                    self.username = ""
                    self.businessCards = []
                    isLoading = false
                    return
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
                self.businessCards = []
                isLoading = false
            }
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.barMenuBackground)
        
        // Configure colors for unselected items
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.bottomNavIcon.opacity(0.6))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(AppColors.bottomNavIcon.opacity(0.6))]
        
        // Configure colors for selected items
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.bottomNavIcon)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppColors.bottomNavIcon)]

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private func fetchUserProStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                let fetchedIsPro = document.data()?["isPro"] as? Bool ?? false
                DispatchQueue.main.async {
                    self.isPro = fetchedIsPro
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
