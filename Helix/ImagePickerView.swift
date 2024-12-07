//
//  ImagePickerView.swift
//  Helix
//
//  Created by Richard Waithe on 12/7/24.
//

import SwiftUI
import Vision
import PhotosUI

struct ImagePickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingManualEntry = false
    @State private var scannedData = ScannedContactData()
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onImagePicked: (UIImage) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if isProcessing {
                ProcessingOverlay(message: "Processing...")
            } else {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                        Text("Select Photo")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .onChange(of: selectedItem) { newValue in
                    processSelectedImage()
                }
            }
        }
        .padding()
        .navigationTitle("Select Photo")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") { dismiss() },
            trailing: Button("Enter Manually") { showingManualEntry = true }
        )
        .sheet(isPresented: $showingManualEntry) {
            CreateContactView(prefilledData: scannedData)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func processSelectedImage() {
        guard let selectedItem = selectedItem else { return }
        
        isProcessing = true
        
        Task {
            do {
                guard let imageData = try await selectedItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: imageData) else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                }
                
                onImagePicked(uiImage)
                
                let textRecognizer = TextRecognizer()
                let recognizedText = try await textRecognizer.recognizeText(from: uiImage)
                let processor = TextProcessor()
                let processed = processor.processText(recognizedText)
                
                await MainActor.run {
                    self.scannedData = processed.data
                    self.showingManualEntry = true
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to process image: \(error.localizedDescription)"
                    self.showError = true
                    self.isProcessing = false
                }
            }
        }
    }
}

