//
//  SettingsView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI
import Firebase

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showDeleteConfirmation = false
    @Binding var isAuthenticated: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var scrollOffset: CGFloat = 0  // Track scroll offset

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                    .opacity(headerOpacity)  // Apply fade-out effect

                VStack(spacing: 0) {
                    // Appearance Section
                    Text("Appearance")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 10)
                        .padding(.leading, 16)  // Added left padding
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .padding(.vertical, 8)  // Reduced vertical padding
                            .padding(.horizontal, 16)
                            .background(AppColors.inputFieldBackground)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .padding(.bottom, 20)

                    // Account Section
                    Text("Account")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 10)
                        .padding(.leading, 16)  // Added left padding
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        Button(action: {
                            authManager.signOut()
                        }) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)  // Reduced vertical padding
                                .padding(.horizontal, 16)
                                .background(AppColors.inputFieldBackground)
                        }

                        Divider()

                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Text("Delete Account")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)  // Reduced vertical padding
                                .padding(.horizontal, 16)
                                .background(AppColors.inputFieldBackground)
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScrollOffsetKey.self, value: -proxy.frame(in: .named("scroll")).origin.y)
                }
            )
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                self.scrollOffset = value
            }
        }
        .coordinateSpace(name: "scroll")
        .background(AppColors.background)
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to delete your account? This action is irreversible."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteAccount()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }

    // Calculate opacity based on scroll offset
    private var headerOpacity: Double {
        let opacity = 1.0 - Double(scrollOffset) / 100.0
        return max(0, min(1, opacity))
    }

    private func deleteAccount() {
        // Implement account deletion logic here
    }
}

// Helper to track scroll offset
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
