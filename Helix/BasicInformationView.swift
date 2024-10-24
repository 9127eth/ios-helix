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
    @Binding var showFirstNameError: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true, showFirstNameError: Binding<Bool>) {
        self._businessCard = businessCard
        self.showHeader = showHeader
        self._showFirstNameError = showFirstNameError
    }
    
    enum Field: Hashable {
        case firstName, middleName, lastName, prefix, pronouns, aboutMe
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showHeader {
                Text("Basic Information")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            ErrorTextField(title: "First Name*", text: $businessCard.firstName, showError: $showFirstNameError, onCommit: { focusedField = .middleName })
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
            .focused($focusedField, equals: .pronouns)
                    }
            VStack(alignment: .leading, spacing: 8) {
                Text("About Me")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)
                
                TextEditor(text: Binding(
                    get: { businessCard.aboutMe ?? "" },
                    set: { businessCard.aboutMe = $0.isEmpty ? nil : $0 }
                ))
                .frame(height: 100)
                .padding(8)
                .background(AppColors.textFieldBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .focused($focusedField, equals: .aboutMe)
            }
        }
        .padding(.top, showHeader ? 0 : 16)
    }
}

struct BasicInformationView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInformationView(
            businessCard: .constant(BusinessCard(cardSlug: "", firstName: "")),
            showFirstNameError: .constant(false)
        )
    }
}

