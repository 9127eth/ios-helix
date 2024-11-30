import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TagPickerView: View {
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    @Environment(\.dismiss) var dismiss
    @State private var newTagName = ""
    @State private var showingAddTag = false
    @State private var showingTagManager = false
    
    var body: some View {
        NavigationView {
            List {
                // Selected tags section
                Section(header: Text("Selected Tags")) {
                    if selectedTags.isEmpty {
                        Text("No tags selected")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(Array(selectedTags), id: \.self) { tag in
                            HStack {
                                Text(tag)
                                Spacer()
                                Button(action: { selectedTags.remove(tag) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                // Available tags section
                Section(header: Text("Available Tags")) {
                    ForEach(availableTags.filter { !selectedTags.contains($0) }, id: \.self) { tag in
                        Button(action: { selectedTags.insert(tag) }) {
                            HStack {
                                Text(tag)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(AppColors.foreground)
                            }
                        }
                    }
                    
                    Button(action: { showingAddTag = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add New Tag")
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") { dismiss() }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage") {
                        showingTagManager = true
                    }
                }
            }
            .sheet(isPresented: $showingAddTag) {
                AddTagView { newTag in
                    // Handle adding new tag
                    guard let userId = Auth.auth().currentUser?.uid else { return }
                    let db = Firestore.firestore()
                    db.collection("users").document(userId).collection("tags")
                        .addDocument(data: ["name": newTag, "createdAt": Date()])
                }
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagerView(availableTags: availableTags)
            }
        }
    }
}

// Add Tag View
struct AddTagView: View {
    @Environment(\.dismiss) var dismiss
    @State private var tagName = ""
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Tag Name", text: $tagName)
            }
            .navigationTitle("New Tag")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    if !tagName.isEmpty {
                        onAdd(tagName)
                        dismiss()
                    }
                }
                .disabled(tagName.isEmpty)
            )
        }
    }
}

// Tag Manager View
struct TagManagerView: View {
    let availableTags: [String]
    @Environment(\.dismiss) var dismiss
    @State private var tagsToDelete: Set<String> = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableTags, id: \.self) { tag in
                    HStack {
                        Text(tag)
                        Spacer()
                        Button(action: {
                            if tagsToDelete.contains(tag) {
                                tagsToDelete.remove(tag)
                            } else {
                                tagsToDelete.insert(tag)
                            }
                        }) {
                            Image(systemName: tagsToDelete.contains(tag) ? "trash.fill" : "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Manage Tags")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") {
                    deleteSelectedTags()
                    dismiss()
                }
            )
        }
    }
    
    private func deleteSelectedTags() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        for tag in tagsToDelete {
            db.collection("users").document(userId).collection("tags")
                .whereField("name", isEqualTo: tag)
                .getDocuments { snapshot, error in
                    if let documents = snapshot?.documents {
                        for document in documents {
                            document.reference.delete()
                        }
                    }
                }
        }
    }
} 