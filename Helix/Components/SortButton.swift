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
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                Text("Sort")
            }
            .padding(8)
            .background(AppColors.inputFieldBackground)
            .cornerRadius(8)
        }
    }
} 