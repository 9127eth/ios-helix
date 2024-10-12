//
//  BasicInformationView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//
import SwiftUI

struct BasicInformationView: View {
    @Binding var businessCard: BusinessCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("First Name", text: $businessCard.firstName)
            TextField("Middle Name", text: Binding(
                get: { businessCard.middleName ?? "" },
                set: { businessCard.middleName = $0.isEmpty ? nil : $0 }
            ))
            TextField("Last Name", text: Binding(
                get: { businessCard.lastName ?? "" },
                set: { businessCard.lastName = $0.isEmpty ? nil : $0 }
            ))
            TextField("Prefix", text: Binding(
                get: { businessCard.prefix ?? "" },
                set: { businessCard.prefix = $0.isEmpty ? nil : $0 }
            ))
            TextField("Credentials", text: Binding(
                get: { businessCard.credentials ?? "" },
                set: { businessCard.credentials = $0.isEmpty ? nil : $0 }
            ))
            TextField("Pronouns", text: Binding(
                get: { businessCard.pronouns ?? "" },
                set: { businessCard.pronouns = $0.isEmpty ? nil : $0 }
            ))
            TextField("Job Title", text: Binding(
                get: { businessCard.jobTitle ?? "" },
                set: { businessCard.jobTitle = $0.isEmpty ? nil : $0 }
            ))
            TextField("Company", text: Binding(
                get: { businessCard.company ?? "" },
                set: { businessCard.company = $0.isEmpty ? nil : $0 }
            ))
            TextEditor(text: $businessCard.description)
                .frame(height: 100)
                .border(Color.gray, width: 1)
            TextEditor(text: Binding(
                get: { businessCard.aboutMe ?? "" },
                set: { businessCard.aboutMe = $0.isEmpty ? nil : $0 }
            ))
                .frame(height: 100)
                .border(Color.gray, width: 1)
        }
    }
}
