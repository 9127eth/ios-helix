//
//  ContactInformationView..swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct ContactInformationView: View {
    @Binding var businessCard: BusinessCard
    
    var body: some View {
        VStack(spacing: 20) {
            CustomTextField(title: "Phone Number", text: Binding($businessCard.phoneNumber) ?? Binding.constant(""))
            CustomTextField(title: "Email", text: Binding($businessCard.email) ?? Binding.constant(""))
        }
    }
}
