import SwiftUI

struct SortButton: View {
    @Binding var selectedOption: MyContactsView.SortOption
    
    var body: some View {
        Menu {
            Button(action: { selectedOption = .name }) {
                HStack {
                    Text("Name")
                    if selectedOption == .name {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: { selectedOption = .dateAdded }) {
                HStack {
                    Text("Date Added")
                    if selectedOption == .dateAdded {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .renderingMode(.template)
                Text("Sort")
                    .font(.footnote)
            }
            .foregroundColor(AppColors.buttonText)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppColors.cardGridBackground)
            .cornerRadius(16)
        }
    }
} 