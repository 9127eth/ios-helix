import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SeeContactView: View {
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @StateObject private var tagManager = TagManager()
    @State private var showingZoomableImage = false
    @State private var showingContactOptions = false
    @State private var shareImage: UIImage?
    @State private var showingShareSheet = false
    
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
                
                // Image Section
                if let imageUrl = contact.imageUrl {
                    Section {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            VStack(spacing: 12) {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        showingZoomableImage = true
                                    }
                                    .contentShape(Rectangle())
                                
                                Button {
                                    shareImage(imageUrl: imageUrl)
                                } label: {
                                    Label("Share Image", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                            }
                        } placeholder: {
                            ProgressView()
                                .frame(height: 200)
                        }
                    }
                }
                
                // Add some spacing
                Section {
                    EmptyView()
                }
                .listRowBackground(Color.clear)
                .frame(height: 20)
                
                // Contact Button Section at the very bottom
                Section {
                    if contact.phone != nil || contact.email != nil {
                        Button {
                            showingContactOptions = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Contact")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.large)
            .padding(.top, 10)
            .background(Color(uiColor: .systemGroupedBackground))
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
        .sheet(isPresented: $showingContactOptions) {
            ContactOptionsSheet(contact: contact)
                .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .onAppear {
            tagManager.fetchTags()
        }
    }
    
    private func shareImage(imageUrl: String) {
        guard let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let uiImage = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self.shareImage = uiImage
                self.showingShareSheet = true
            }
        }.resume()
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 