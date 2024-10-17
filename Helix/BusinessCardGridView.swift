//
//  BusinessCardView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//

import SwiftUI

struct BusinessCardGridView: View {
    @Binding var businessCards: [BusinessCard]
    @Binding var showCreateCard: Bool
    let username: String
    
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                        .opacity(headerOpacity)
                    
                    // Reduce the Spacer height by 50%
                    Spacer(minLength: UIScreen.main.bounds.height * 0.035)
                    
                    HStack {
                        Spacer()
                        Button(action: { showCreateCard = true }) {
                            Label("Create New", systemImage: "plus")
                                .font(.footnote)
                                .foregroundColor(AppColors.buttonText)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(AppColors.buttonBackground)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    LazyVStack(spacing: 16) {
                        ForEach($businessCards) { $card in
                            BusinessCardItemView(card: $card, username: username)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: 0xe5e6ed), lineWidth: 1)
                                        .opacity(colorScheme == .dark ? 1 : 0)
                                )
                        }
                        AddCardButton(action: { showCreateCard = true })
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
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Business Cards")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You must be the change you wish to see in the world. -Mahatma Gandhi")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    private var headerOpacity: Double {
        let opacity = 1.0 - Double(scrollOffset) / 100.0
        return max(0, min(1, opacity))
    }
}
