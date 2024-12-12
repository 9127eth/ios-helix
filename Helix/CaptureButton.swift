//
//  CaptureButton.swift
//  Helix
//
//  Created by Richard Waithe on 12/9/24.
//

import SwiftUI

struct CaptureButton: View {
    let onTap: () -> Void
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var deviceOrientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }
    
    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(Color.white)
                .frame(width: 70, height: 70)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 60, height: 60)
                )
        }
    }
}

