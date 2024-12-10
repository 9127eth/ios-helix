import SwiftUI

struct SortButton: View {
    @Binding var selectedOption: MyContactsView.SortOption
    
    var body: some View {
        Menu {
            Button(action: { selectedOption = .name }) {
                HStack(spacing: 8) {
                    Image("sort")
                        .renderingMode(.template)
                    Text("Name")
                        .font(.footnote)
                    if selectedOption == .name {
                        Image(systemName: "checkmark")
                    }
                }
                .foregroundColor(AppColors.bodyPrimaryText)
            }
            
            Button(action: { selectedOption = .dateAdded }) {
                HStack(spacing: 8) {
                    Image("sort")
                        .renderingMode(.template)
                    Text("Date Added")
                        .font(.footnote)
                    if selectedOption == .dateAdded {
                        Image(systemName: "checkmark")
                    }
                }
                .foregroundColor(AppColors.bodyPrimaryText)
            }
        } label: {
            HStack(spacing: 8) {
                Image("sort")
                    .renderingMode(.template)
                Text("Sort")
                    .font(.footnote)
            }
            .foregroundColor(AppColors.bodyPrimaryText)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppColors.cardGridBackground)
            .cornerRadius(16)
        }
    }
} 