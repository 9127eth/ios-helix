//
//  ProfessionalInformationView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct ProfessionalInformationView: View {
    @Binding var businessCard: BusinessCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Professional Information")
                .font(.headline)
            CustomTextField(title: "Credentials", text: Binding($businessCard.credentials) ?? Binding.constant(""))
            CustomTextField(title: "Job Title", text: Binding($businessCard.jobTitle) ?? Binding.constant(""))
            CustomTextField(title: "Company", text: Binding($businessCard.company) ?? Binding.constant(""))
        }
    }
}
