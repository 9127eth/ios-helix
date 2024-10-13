//
//  ProfileImageView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct ProfileImageView: View {
    @Binding var businessCard: BusinessCard
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add an Image")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(spacing: 20) {
                if let imageUrl = businessCard.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppColors.primary, lineWidth: 4))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 200, height: 200)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .foregroundColor(.gray)
                        .overlay(Circle().stroke(AppColors.primary, lineWidth: 4))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                
                Button(action: { showImagePicker = true }) {
                    Text("Select Image")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppColors.primary)
                        .cornerRadius(20)
                }
            }
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
        guard let inputImage = inputImage else { return }
        // Implement image upload logic here
        // After successful upload, update businessCard.imageUrl
        // For now, let's use a temporary local URL
        if let imageData = inputImage.jpegData(compressionQuality: 0.8),
           let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            try? imageData.write(to: fileURL)
            businessCard.imageUrl = fileURL.absoluteString
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
