//
//  TagSelectionView.swift
//  Helix
//
//  Created by Richard Waithe on 11/30/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TagSelectionView: View {
    @ObservedObject var tagManager: TagManager
    @Binding var selectedTagIds: Set<String>
    @State private var newTagName = ""
    @State private var showingAddTag = false
    @State private var showingDeleteConfirmation = false
    @State private var tagToDelete: Tag?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Selected tags section
                Section(header: Text("Selected Tags")) {
                    if selectedTagIds.isEmpty {
                        Text("No tags selected")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(Array(selectedTagIds), id: \.self) { tagId in
                            if let tag = tagManager.availableTags.first(where: { $0.id == tagId }) {
                                HStack {
                                    Text(tag.name)
                                    Spacer()
                                    Button(action: { selectedTagIds.remove(tagId) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Available tags section
                Section(header: Text("Available Tags")) {
                    ForEach(tagManager.availableTags.filter { !selectedTagIds.contains($0.id ?? "") }) { tag in
                        HStack {
                            Button(action: {
                                if let id = tag.id {
                                    selectedTagIds.insert(id)
                                }
                            }) {
                                HStack {
                                    Text(tag.name)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(AppColors.foreground)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                tagToDelete = tag
                                showingDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Button(action: { showingAddTag = true }) {
                        Label("Add New Tag", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Add New Tag", isPresented: $showingAddTag) {
                TextField("Tag Name", text: $newTagName)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    Task {
                        if !newTagName.isEmpty {
                            do {
                                let newTag = try await tagManager.createTag(newTagName)
                                if let id = newTag.id {
                                    selectedTagIds.insert(id)
                                }
                                newTagName = ""
                            } catch {
                                print("Error creating tag: \(error)")
                            }
                        }
                    }
                }
            }
            .alert("Delete Tag?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let tag = tagToDelete, let id = tag.id {
                        Task {
                            do {
                                try await tagManager.deleteTag(id)
                            } catch {
                                print("Error deleting tag: \(error)")
                            }
                        }
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

