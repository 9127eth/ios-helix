//
//  TagManagerView.swift
//  Helix
//
//  Created by Richard Waithe on 11/30/24.
//

import SwiftUI

struct TagManagerView: View {
    @StateObject private var tagManager = TagManager()
    @Environment(\.dismiss) var dismiss
    @State private var newTagName = ""
    @State private var showingAddTag = false
    @State private var showingDeleteConfirmation = false
    @State private var tagToDelete: Tag?
    @State private var showingTooltip = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: HStack {
                    Text("Available Tags")
                    Image("tooltip")
                        .onTapGesture {
                            showingTooltip = true
                        }
                }) {
                    ForEach(tagManager.availableTags) { tag in
                        HStack {
                            Text(tag.name)
                                .foregroundColor(AppColors.bodyPrimaryText)
                            Spacer()
                            Button(action: {
                                tagToDelete = tag
                                showingDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .contentShape(Rectangle())
                    }
                    
                    Button(action: { showingAddTag = true }) {
                        Label("Add New Tag", image: "tag")
                    }
                }
            }
            .navigationTitle("Manage Tags")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Add New Tag", isPresented: $showingAddTag) {
                TextField("Tag Name", text: $newTagName)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    Task {
                        if !newTagName.isEmpty {
                            do {
                                _ = try await tagManager.createTag(newTagName)
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
            .alert("What are tags?", isPresented: $showingTooltip) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Tags allow you to group contacts together. You can use tags to filter, delete, and export contacts in bulk.")
            }
        }
        .onAppear {
            tagManager.fetchTags()
        }
    }
}

