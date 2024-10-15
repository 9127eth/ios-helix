//
//  CustomSectionView.swift
//  Helix
//
//  Created by Richard Waithe on 10/14/24.
//

import SwiftUI

struct CustomSectionView: View {
    @Binding var businessCard: BusinessCard
    @FocusState private var focusedField: Field?
    var showHeader: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }
    
    enum Field: Hashable {
        case customMessageHeader, customMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Custom Header/Message")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            CustomTextField(title: "Custom Header", text: Binding(
                get: { businessCard.customMessageHeader ?? "" },
                set: { businessCard.customMessageHeader = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = .customMessage })
                .focused($focusedField, equals: .customMessageHeader)
            
            CustomTextEditor(title: "Custom Message", text: Binding(
                get: { businessCard.customMessage ?? "" },
                set: { businessCard.customMessage = $0.isEmpty ? nil : $0 }
            ))
                .focused($focusedField, equals: .customMessage)
        }
        .padding(.top, showHeader ? 0 : 16)
    }
}
