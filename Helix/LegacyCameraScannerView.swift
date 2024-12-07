//
//  LegacyCameraScannerView.swift
//  Helix
//
//  Created by Richard Waithe on 12/7/24.
//

import SwiftUI
import Vision
import VisionKit
import AVFoundation

struct LegacyCameraScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingManualEntry = false
    @State private var isProcessing = false
    @State private var showProcessingError = false
    @State private var errorMessage = ""
    @State private var scannedData = ScannedContactData()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                CameraPreview { result in
                    switch result {
                    case .success(let image):
                        handleCapturedImage(image)
                    case .failure(let error):
                        showError(error.localizedDescription)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Processing overlay
                if isProcessing {
                    ProcessingOverlay(message: "Processing card...")
                }
                
                // Bottom controls
                VStack {
                    Spacer()
                    ControlsView(
                        onCapture: {}, // Handled by CameraPreview
                        onManualEntry: { showingManualEntry = true }
                    )
                }
            }
            .navigationTitle("Scan Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            CreateContactView(prefilledData: scannedData)
        }
        .alert("Error", isPresented: $showProcessingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let textRecognizer = TextRecognizer()
                let recognizedText = try await textRecognizer.recognizeText(from: image)
                let processor = TextProcessor()
                let processed = processor.processText(recognizedText)
                
                await MainActor.run {
                    self.scannedData = processed.data
                    self.showingManualEntry = true
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showProcessingError = true
        isProcessing = false
    }
}

// Supporting Views
struct CardOverlayView: View {
    var body: some View {
        Rectangle()
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
            .foregroundColor(.white)
            .frame(width: 280, height: 180)
            .overlay(
                Text("Align card within frame")
                    .foregroundColor(.white)
                    .padding(.top, 200)
            )
    }
}

struct ControlsView: View {
    let onCapture: () -> Void
    let onManualEntry: () -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            Button(action: onManualEntry) {
                Text("Enter Manually")
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(8)
            }
            
            Button(action: onCapture) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 60, height: 60)
                    )
            }
        }
        .padding(.bottom, 30)
    }
}

// Add preview provider if needed
#Preview {
    LegacyCameraScannerView()
}

