import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SeeContactView: View {
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @StateObject private var tagManager = TagManager()
    @State private var showingZoomableImage = false
    
    var body: some View {
        NavigationView {
            Form {
                // Add padding at the top
                Section {
                    EmptyView()
                }
                .listRowBackground(Color.clear)
                .frame(height: 20)
                
                Section {
                    HStack {
                        Text(contact.name)
                            .textSelection(.enabled)
                        Spacer()
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let position = contact.position {
                        HStack {
                            Text(position)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Position")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let company = contact.company {
                        HStack {
                            Text(company)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Company")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let phone = contact.phone {
                        HStack {
                            Text(phone)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Phone")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let email = contact.email {
                        HStack {
                            Text(email)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let website = contact.website {
                        HStack {
                            Text(website)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Website")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let address = contact.address {
                        HStack {
                            Text(address)
                                .textSelection(.enabled)
                            Spacer()
                            Text("Address")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if let tags = contact.tags, !tags.isEmpty {
                    Section {
                        ForEach(tags, id: \.self) { tagId in
                            if let tag = tagManager.availableTags.first(where: { $0.id == tagId }) {
                                HStack {
                                    Text(tag.name)
                                        .textSelection(.enabled)
                                    Spacer()
                                    Text("Tag")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                if let note = contact.note {
                    Section {
                        HStack {
                            Text(note)
                                .textSelection(.enabled)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Image Section at the bottom
                if let imageUrl = contact.imageUrl {
                    Section {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .onTapGesture {
                                    showingZoomableImage = true
                                }
                        } placeholder: {
                            ProgressView()
                                .frame(height: 200)
                        }
                    }
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditContactView(contact: .constant(contact))
        }
        .sheet(isPresented: $showingZoomableImage) {
            if let imageUrl = contact.imageUrl {
                ZoomableImageView(imageUrl: imageUrl)
            }
        }
        .onAppear {
            tagManager.fetchTags()
        }
    }
}

struct ZoomableImageView: View {
    let imageUrl: String
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                scale = scale > 1 ? 1 : 2
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                } placeholder: {
                    ProgressView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 