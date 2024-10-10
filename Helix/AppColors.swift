//
//  AppColors.swift
//  Helix
//
//  Created by Richard Waithe on 10/10/24.
//
import SwiftUI

struct AppColors {
    static let background = Color(hex: 0xEFEFEF)
    static let foreground = Color.black
    static let primary = Color(hex: 0x93DBD6)
    static let primaryText = Color.black
    static let cardGridBackground = Color.white
    static let bodyPrimaryText = Color(hex: 0x333333)
    static let barMenuBackground = Color(hex: 0xF5FDFD)
    
    // Helper initializer to create colors from hex values
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
