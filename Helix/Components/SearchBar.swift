import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image("search")
                .renderingMode(.template)
                .foregroundColor(AppColors.bodyPrimaryText)
            
            TextField("Search contacts", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(AppColors.bodyPrimaryText)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.bodyPrimaryText.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppColors.cardGridBackground)
        .cornerRadius(16)
    }
} 