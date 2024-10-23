//
//  ProfileImageView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI
import FirebaseStorage
import FirebaseAuth

struct ProfileImageView: View {
    @Binding var businessCard: BusinessCard
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isUploading = false
    @State private var uploadError: String?
    var showHeader: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            if showHeader {
                Text("Add an Image")
                    .font(.headline)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(spacing: 20) {
                if let imageUrl = businessCard.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppColors.divider, lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 100, height: 100)
                    }
                    
                    // Add remove button
                    Button(action: {
                        businessCard.imageUrl = nil  // This only updates the UI locally
                    }) {
                        Text("Remove")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                
                Button(action: { 
                    showImagePicker = true 
                    uploadError = nil
                }) {
                    Text(isUploading ? "Uploading..." : "Select Image")
                        .foregroundColor(AppColors.buttonText)
                        .font(.system(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.buttonBackground)
                        .cornerRadius(16)
                }
                .disabled(isUploading)
                
                if let error = uploadError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $inputImage)
        }
        .onChange(of: inputImage) { _ in
            uploadImage()
        }
    }
    
    private func uploadImage() {
        guard let inputImage = inputImage,
              let imageData = inputImage.jpegData(compressionQuality: 0.8) else { return }
        
        isUploading = true
        uploadError = nil
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        guard let userId = Auth.auth().currentUser?.uid else {
            // Handle the case where there's no authenticated user
            return
        }
        
        let imageName = UUID().uuidString + ".jpg"
        let imageRef = storageRef.child("images/\(userId)/\(imageName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.uploadError = "Error uploading image: \(error.localizedDescription)"
                    self.isUploading = false
                }
                return
            }
            
            imageRef.downloadURL { (url, error) in
                DispatchQueue.main.async {
                    self.isUploading = false
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.uploadError = "Error getting download URL: \(error.localizedDescription)"
                    }
                    return
                }
                
                if let downloadURL = url {
                    DispatchQueue.main.async {
                        self.businessCard.imageUrl = downloadURL.absoluteString
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
