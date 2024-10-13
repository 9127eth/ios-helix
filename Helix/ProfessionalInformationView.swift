//
//  ProfessionalInformationView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct ProfessionalInformationView: View {
    @Binding var businessCard: BusinessCard
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case credentials, jobTitle, company
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Professional Information")
                .font(.headline)
            CustomTextField(title: "Credentials", text: Binding($businessCard.credentials) ?? Binding.constant(""), onCommit: { focusedField = .jobTitle })
                .focused($focusedField, equals: .credentials)
            CustomTextField(title: "Job Title", text: Binding($businessCard.jobTitle) ?? Binding.constant(""), onCommit: { focusedField = .company })
                .focused($focusedField, equals: .jobTitle)
            CustomTextField(title: "Company", text: Binding($businessCard.company) ?? Binding.constant(""), onCommit: { focusedField = nil })
                .focused($focusedField, equals: .company)
        }
    }
}