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
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Information")
                .font(.headline)
                .padding(.bottom, 10)
            
            CustomTextField(title: "First Name*", text: $businessCard.firstName)
         
            
            CustomTextField(title: "Middle Name", text: Binding(
                get: { businessCard.middleName ?? "" },
                set: { businessCard.middleName = $0.isEmpty ? nil : $0 }
            ))
            
            CustomTextField(title: "Last Name", text: Binding(
                get: { businessCard.lastName ?? "" },
                set: { businessCard.lastName = $0.isEmpty ? nil : $0 }
            ))
            
            CustomTextField(title: "Prefix", text: Binding(
                get: { businessCard.prefix ?? "" },
                set: { businessCard.prefix = $0.isEmpty ? nil : $0 }
            ))
            
            CustomTextField(title: "Pronouns", text: Binding(
                get: { businessCard.pronouns ?? "" },
                set: { businessCard.pronouns = $0.isEmpty ? nil : $0 }
            ))
        }
        .padding()
    }
}

struct BasicInformationView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInformationView(businessCard: .constant(BusinessCard(cardSlug: "", userId: "", isPrimary: false, username: "", firstName: "")))
    }
}
