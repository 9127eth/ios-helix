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
    static let barMenuBackground = Color("barMenuBackground")
    static let inputFieldBackground = Color("inputFieldBackgroundColor")
    static let buttonBackground = Color("buttonBackgroundColor")
    static let buttonText = Color("buttonTextColor")
    static let divider = Color("dividerColor")
    static let editSheetBackground = Color("editSheetBackgroundColor")
    static let sheetHeaderBackground = Color("sheetHeaderBackgroundColor")
    
    static let bottomNavIcon = Color("bottomNavIcon")
    static let helixPro = Color("helixPro")
    
    static let mainSubBackground = Color("mainSubBackground")
    static let cardSubBackground = Color("cardSubBackground")
    static let cardDepthDefault = Color("cardDepthDefault")
    
    static let tertColor = Color("tertColor")
    
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
