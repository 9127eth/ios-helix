import SwiftUI
import FirebaseFirestore
import Helix

struct TagFilterButton: View {
    @Binding var selectedTags: Set<String>
    @StateObject private var tagManager = TagManager()
    @State private var showingTagPicker = false
    
    var body: some View {
        Button(action: { showingTagPicker = true }) {
            HStack(spacing: 4) {
                Image(systemName: "tag")
                    .renderingMode(.template)
                Text(selectedTags.isEmpty ? "Filter" : "\(selectedTags.count)")
                    .font(.footnote)
            }
            .foregroundColor(AppColors.buttonText)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppColors.cardGridBackground)
            .cornerRadius(16)
        }
        .sheet(isPresented: $showingTagPicker) {
            TagSelectionView(tagManager: tagManager, selectedTagIds: $selectedTags)
        }
        .onAppear {
            tagManager.fetchTags()
        }
    }
} 