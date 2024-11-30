import SwiftUI

struct AddContactButton: View {
    var action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image("newuser")
                    .renderingMode(.template)
                Text("Create New")
                    .font(.footnote)
            }
            .foregroundColor(AppColors.buttonText)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppColors.cardGridBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
} 