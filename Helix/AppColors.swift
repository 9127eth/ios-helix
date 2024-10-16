//
//  AppColors.swift
//  Helix
//
//  Created by Richard Waithe on 10/10/24.
//
import SwiftUI

struct AppColors {
    static let background = Color("backgroundColor")
    static let foreground = Color("foregroundColor")
    static let primary = Color("primaryColor")
    static let primaryText = Color("primaryTextColor")
    static let cardGridBackground = Color("cardGridBackgroundColor")
    static let bodyPrimaryText = Color("bodyPrimaryTextColor")
    static let barMenuBackground = Color("barMenuBackgroundColor")
    static let inputFieldBackground = Color("inputFieldBackgroundColor")
    
    private init() {}
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
