import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let onCapture: (Result<UIImage, Error>) -> Void
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        // Setup preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Setup camera
        setupCamera(previewLayer: previewLayer, view: view, coordinator: context.coordinator)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else { return }
        previewLayer.frame = uiView.bounds
        
        if let connection = previewLayer.connection {
            let currentDevice = UIDevice.current
            let orientation = currentDevice.orientation
            
            if connection.isVideoOrientationSupported {
                switch orientation {
                case .portrait: connection.videoOrientation = .portrait
                case .landscapeRight: connection.videoOrientation = .landscapeLeft
                case .landscapeLeft: connection.videoOrientation = .landscapeRight
                case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
                default: connection.videoOrientation = .portrait
                }
            }
        }
    }
    
    private func setupCamera(previewLayer: AVCaptureVideoPreviewLayer, view: UIView, coordinator: Coordinator) {
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            onCapture(.failure(CameraError.cameraUnavailable))
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        } catch {
            onCapture(.failure(error))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let parent: CameraPreview
        
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
        
        @objc func handleTap() {
            let settings = AVCapturePhotoSettings()
            parent.photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                parent.onCapture(.failure(error))
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let originalImage = UIImage(data: imageData) else {
                parent.onCapture(.failure(CameraError.photoCaptureFailed))
                return
            }
            
            // Get the orientation from the photo's metadata
            if let cgImageOrientation = photo.metadata["{Orientation}"] as? UInt32 {
                let propertyOrientation = CGImagePropertyOrientation(rawValue: cgImageOrientation) ?? .up
                let correctedImage = UIImage(cgImage: originalImage.cgImage!,
                                           scale: originalImage.scale,
                                           orientation: UIImage.Orientation(propertyOrientation))
                parent.onCapture(.success(correctedImage))
            } else {
                // If we can't get the orientation from metadata, use the device orientation
                let deviceOrientation = UIDevice.current.orientation
                let imageOrientation: UIImage.Orientation
                
                switch deviceOrientation {
                case .portrait: imageOrientation = .right
                case .portraitUpsideDown: imageOrientation = .left
                case .landscapeLeft: imageOrientation = .up
                case .landscapeRight: imageOrientation = .down
                default: imageOrientation = .right
                }
                
                let correctedImage = UIImage(cgImage: originalImage.cgImage!,
                                           scale: originalImage.scale,
                                           orientation: imageOrientation)
                parent.onCapture(.success(correctedImage))
            }
        }
    }
    
    enum CameraError: Error {
        case cameraUnavailable
        case photoCaptureFailed
    }
}

extension UIImage.Orientation {
    init(_ cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
} 