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
        VStack(alignment: .leading, spacing: 16) {
            TextField("Phone Number", text: Binding($businessCard.phoneNumber) ?? Binding.constant(""))
            TextField("Email", text: Binding($businessCard.email) ?? Binding.constant(""))
        }
    }
}