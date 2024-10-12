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
                    Image(systemName: "rectangle.on.rectangle")
                    Text("Cards")
                }
            }
            Spacer()
            Button(action: { selectedTab = 1 }) {
                VStack {
                    Image(systemName: "gear")
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
