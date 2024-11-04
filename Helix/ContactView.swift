//
//  ContactView.swift
//  Helix
//
//  Created by Richard Waithe on 11/3/24.
//

import SwiftUI

struct ContactView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Get in touch with our support team")
                    .foregroundColor(AppColors.bodySecondaryText)
                    .padding(.horizontal)
                    .padding(.top)
                
                List {
                    Button(action: {
                        if let url = URL(string: "tel:+17862737007") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(AppColors.foreground)
                            Text("Text")
                            Spacer()
                            Text("+1 (786) 273-7007")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: "mailto:support@helixcard.app") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppColors.foreground)
                            Text("Email")
                            Spacer()
                            Text("support@helixcard.app")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContactView()
}