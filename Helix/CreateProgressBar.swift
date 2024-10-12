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
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    VStack {
                        ZStack {
                            Circle()
                                .fill(index <= currentStep ? AppColors.primary : Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: iconName(for: index))
                                .foregroundColor(index <= currentStep ? .white : .gray)
                        }
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? AppColors.primary : Color.gray.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
            }
            
            Text(steps[currentStep])
                .font(.caption)
                .foregroundColor(AppColors.bodyPrimaryText)
        }
    }
    
    private func iconName(for index: Int) -> String {
        switch index {
        case 0: return "person"
        case 1: return "briefcase"
        case 2: return "text.alignleft"
        case 3: return "envelope"
        case 4: return "link"
        case 5: return "globe"
        case 6: return "camera"
        default: return "circle"
        }
    }
}
