import SwiftUI
import AVFoundation
import VisionKit
import PhotosUI

struct ContactCreationEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showManualEntry = false
    @State private var showImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var scannedData: ScannedContactData?
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cameraPermissionGranted = false
    @Binding var isPresented: Bool
    @State private var selectedItem: PhotosPickerItem?
    @State private var orientation = UIDevice.current.orientation
    
    var body: some View {
        NavigationView {
            ZStack {
                if cameraPermissionGranted {
                    // Camera preview takes up full screen
                    CameraPreview { result in
                        switch result {
                        case .success(let image):
                            self.capturedImage = image
                            processImage(image)
                        case .failure(let error):
                            showError = true
                            errorMessage = error.localizedDescription
                        }
                    }
                    .ignoresSafeArea()
                } else {
                    // Show permission request view
                    VStack {
                        Text("Camera access is required to scan business cards")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Grant Camera Access") {
                            requestCameraPermission()
                        }
                        .padding()
                        
                        Button("Enter Manually") {
                            showManualEntry = true
                        }
                        .padding()
                    }
                }
                
                // Bottom controls overlay
                VStack {
                    Spacer()
                    if UIDevice.current.orientation.isPortrait {  // Only show in portrait
                        HStack(spacing: 20) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                VStack {
                                    Image("addImage")
                                    Text("Choose Photo")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                            }
                            .onChange(of: selectedItem) { newValue in
                                Task {
                                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        self.capturedImage = uiImage
                                        processImage(uiImage)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: { showManualEntry = true }) {
                                VStack {
                                    Image("entermanually")
                                        .renderingMode(.template)
                                    Text("Enter Manually")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Close") { dismiss() })
        }
        .sheet(isPresented: $showManualEntry) {
            CreateContactView(
                prefilledData: scannedData,
                onSave: {
                    dismiss()
                    isPresented = false
                }
            )
        }
        .overlay(
            Group {
                if isProcessing {
                    ProcessingOverlay()
                }
            }
        )
        .onAppear {
            checkCameraPermission()
            
            // Add orientation observer
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                orientation = UIDevice.current.orientation
            }
        }
        .onDisappear {
            // Remove orientation observer
            NotificationCenter.default.removeObserver(
                self,
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera permission authorized")
            cameraPermissionGranted = true
        case .notDetermined:
            print("Camera permission not determined")
            requestCameraPermission()
        case .denied, .restricted:
            print("Camera permission denied or restricted")
            cameraPermissionGranted = false
        @unknown default:
            print("Unknown camera permission status")
            cameraPermissionGranted = false
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                print("Camera permission granted: \(granted)")
                self.cameraPermissionGranted = granted
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let textRecognizer = TextRecognizer()
                let processedData = try await textRecognizer.recognizeAndProcessText(from: image)
                
                await MainActor.run {
                    self.scannedData = processedData
                    self.isProcessing = false
                    self.showManualEntry = true
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
