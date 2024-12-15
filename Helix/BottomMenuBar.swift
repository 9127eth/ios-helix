//
//  BottomMenuBar.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//

import SwiftUI

struct BottomMenuBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack {
            Spacer()
            Button(action: { selectedTab = 0 }) {
                VStack {
                    Image("cardsNavi")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text("My Cards")
                }
            }
            Spacer()
            Button(action: { selectedTab = 1 }) {
                VStack {
                    Image("settingsNavi")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text("Settings")
                }
            }
            Spacer()
        }
        .padding()
        .background(AppColors.barMenuBackground)
        .shadow(radius: 2)
    }
}
