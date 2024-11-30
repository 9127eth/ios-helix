import SwiftUI

struct TagFilterButton: View {
    @Binding var selectedTags: Set<String>
    @State private var showingTagPicker = false
    @State private var availableTags: [String] = []
    
    var body: some View {
        Button(action: { showingTagPicker = true }) {
            HStack {
                Image(systemName: "tag")
                Text(selectedTags.isEmpty ? "Filter by tag" : "\(selectedTags.count) tags")
                    .foregroundColor(selectedTags.isEmpty ? .gray : AppColors.foreground)
            }
            .padding(8)
            .background(AppColors.inputFieldBackground)
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingTagPicker) {
            TagPickerView(selectedTags: $selectedTags, availableTags: availableTags)
        }
        .onAppear {
            // Fetch available tags from Firestore
            fetchAvailableTags()
        }
    }
    
    private func fetchAvailableTags() {
        // Implementation will be added with Firebase integration
    }
} 