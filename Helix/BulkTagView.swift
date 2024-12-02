import SwiftUI
import FirebaseFirestore

struct BulkTagView: View {
    let selectedContactIds: Set<String>
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var tagManager = TagManager()
    @State private var selectedTags: Set<String> = []
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(tagManager.availableTags) { tag in
                        HStack {
                            Text(tag.name)
                            Spacer()
                            if selectedTags.contains(tag.id ?? "") {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let id = tag.id {
                                toggleTag(id)
                            }
                        }
                    }
                } header: {
                    Text("Select tags to apply")
                }
            }
            .navigationTitle("Add Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyTagsToContacts()
                    }
                    .disabled(selectedTags.isEmpty || isProcessing)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            tagManager.fetchTags()
        }
    }
    
    private func toggleTag(_ tagId: String) {
        if selectedTags.contains(tagId) {
            selectedTags.remove(tagId)
        } else {
            selectedTags.insert(tagId)
        }
    }
    
    private func applyTagsToContacts() {
        guard !selectedTags.isEmpty else { return }
        isProcessing = true
        
        Task {
            do {
                try await Contact.bulkUpdateTags(selectedContactIds, addTags: selectedTags)
                await MainActor.run {
                    dismiss()
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
} 