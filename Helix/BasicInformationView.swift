//
//  BasicInformationView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//
import SwiftUI

struct BasicInformationView: View {
    @Binding var businessCard: BusinessCard
    @FocusState private var focusedField: Field?
    var showHeader: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }
    
    enum Field: Hashable {
        case firstName, middleName, lastName, prefix, pronouns
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showHeader {
                Text("Basic Information")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            CustomTextField(title: "First Name*", text: $businessCard.firstName, onCommit: { focusedField = .middleName })
                .focused($focusedField, equals: .firstName)
            
            CustomTextField(title: "Middle Name", text: Binding(
                get: { businessCard.middleName ?? "" },
                set: { businessCard.middleName = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = .lastName })
                .focused($focusedField, equals: .middleName)
            
            CustomTextField(title: "Last Name", text: Binding(
                get: { businessCard.lastName ?? "" },
                set: { businessCard.lastName = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = .prefix })
                .focused($focusedField, equals: .lastName)
            
            HStack(spacing: 16) {
                CustomTextField(title: "Prefix", text: Binding(
                    get: { businessCard.prefix ?? "" },
                    set: { businessCard.prefix = $0.isEmpty ? nil : $0 }
                ), onCommit: { focusedField = .pronouns })
                    .focused($focusedField, equals: .prefix)
                
                CustomTextField(title: "Pronouns", text: Binding(
                    get: { businessCard.pronouns ?? "" },
                    set: { businessCard.pronouns = $0.isEmpty ? nil : $0 }
                ), onCommit: { focusedField = nil })
                    .focused($focusedField, equals: .pronouns)
            }
        }
        .padding(.top, showHeader ? 0 : 16)
    }
}

struct BasicInformationView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInformationView(businessCard: .constant(BusinessCard(cardSlug: "", firstName: "")))
    }
}
