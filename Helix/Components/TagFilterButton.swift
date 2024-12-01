import SwiftUI
import FirebaseFirestore
import Helix

struct TagFilterButton: View {
    @Binding var selectedTags: Set<String>
    @StateObject private var tagManager = TagManager()
    @State private var showingTagPicker = false
    
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
            TagSelectionView(tagManager: tagManager, selectedTagIds: $selectedTags)
        }
        .onAppear {
            tagManager.fetchTags()
        }
    }
} 