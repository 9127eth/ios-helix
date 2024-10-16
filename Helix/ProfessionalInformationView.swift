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
    var showHeader: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }
    
    enum Field: Hashable {
        case credentials, jobTitle, company
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Professional Information")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            CustomTextField(
                title: "Credentials",
                text: Binding(
                    get: { businessCard.credentials ?? "" },
                    set: { businessCard.credentials = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "PharmD, BSN, JD, MD, etc...",
                onCommit: { focusedField = .jobTitle }
            )
            .focused($focusedField, equals: .credentials)
            
            CustomTextField(title: "Job Title", text: Binding(
                get: { businessCard.jobTitle ?? "" },
                set: { businessCard.jobTitle = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = .company })
                .focused($focusedField, equals: .jobTitle)
            
            CustomTextField(title: "Company", text: Binding(
                get: { businessCard.company ?? "" },
                set: { businessCard.company = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = nil })
                .focused($focusedField, equals: .company)
        }
        .padding(.top, showHeader ? 0 : 16)
    }
}
