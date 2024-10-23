// 
//  CreateProgressBar.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

public struct CreateProgressBar: View {
    let steps = ["Basic Information", "Professional Information", "Description", "Contact Information", "Social Links", "Web Links", "Profile Image"]
    let currentStep: Int
    
    public init(currentStep: Int) {
        self.currentStep = currentStep
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                ZStack {
                    Circle()
                        .fill(circleColor(for: index))
                        .frame(width: 40, height: 40)
                    
                    Image(iconName(for: index))
                        .renderingMode(.template)
                        .foregroundColor(index <= currentStep ? .black : .gray)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 40, height: 40)
                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func circleColor(for index: Int) -> Color {
        if index == currentStep {
            return AppColors.primary
        } else if index < currentStep {
            return Color.gray.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    private func iconName(for index: Int) -> String {
        switch index {
        case 0: return "profile"
        case 1: return "briefcase"
        case 2: return "Label"
        case 3: return "email"
        case 4: return "social"
        case 5: return "Link"
        case 6: return "upload"
        default: return "circle"
        }
    }
}
