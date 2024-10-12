//
//  ShareView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI
import Photos

struct ShareView: View {
    let card: BusinessCard
    @Binding var isPresented: Bool
    @State private var qrCode: UIImage?
    @State private var selectedFormat: ImageFormat = .png
    @State private var noBackground: Bool = false
    @State private var showCopiedCheckmark = false
    
    enum ImageFormat: String, CaseIterable {
        case png = "PNG"
        case jpeg = "JPEG"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(card.name)
                        .font(.system(size: 40, weight: .bold))
                        .fontWeight(.bold)
                    
                    HStack(spacing: 5) {
                        if let jobTitle = card.jobTitle {
                            Text(jobTitle)
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        
                        if card.jobTitle != nil && card.company != nil {
                            Text("|")
                                .font(.system(size: 20))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        if let company = card.company {
                            Text(company)
                                .font(.system(size: 20))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    .padding(.bottom, 20)
                    
                    VStack(alignment: .center, spacing: 30) {
                        if let qrCode = qrCode {
                            Image(uiImage: qrCode)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        
                        Text(card.getCardURL())
                            .font(.caption)
                        
                        // Buttons with adjusted width, standardized height, and increased spacing
                        VStack(spacing: 15) {
                            Button(action: {
                                UIPasteboard.general.string = card.getCardURL()
                                withAnimation {
                                    showCopiedCheckmark = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        showCopiedCheckmark = false
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: showCopiedCheckmark ? "checkmark" : "doc.on.doc")
                                    Text(showCopiedCheckmark ? "Copied!" : "Copy Link")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(AppColors.primary)
                                .foregroundColor(AppColors.primaryText)
                                .cornerRadius(20)
                            }
                            .frame(width: 320)
                            
                            Button(action: {
                                let url = card.getCardURL()
                                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first,
                                   let rootViewController = window.rootViewController {
                                    // Present the activity view controller directly
                                    rootViewController.presentedViewController?.present(activityViewController, animated: true, completion: nil)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Link")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                            .frame(width: 320)
                        }
                        
                        // Section divider with a thin gray line and padding
                        Divider()
                            .background(Color.gray.opacity(0.5))
                            .padding(.vertical, 10)
                        
                        VStack(alignment: .center, spacing: 15) {
                            Text("Share QR Code")
                                .font(.headline)
                            
                            Picker("Select Format", selection: $selectedFormat) {
                                ForEach(ImageFormat.allCases, id: \.self) { format in
                                    Text(format.rawValue).tag(format)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            
                            if selectedFormat == .png {
                                Toggle("Transparent background", isOn: $noBackground)
                                    .padding(.horizontal)
                            }
                            
                            Button(action: shareQRCode) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share QR Code")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(AppColors.primary)
                                .foregroundColor(AppColors.primaryText)
                                .cornerRadius(20)
                            }
                            .frame(width: 320)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationBarItems(trailing: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
                    .font(.system(size: 20, weight: .bold))
            })
        }
        .background(AppColors.background.edgesIgnoringSafeArea(.all))
        .onAppear(perform: generateQRCode)
    }
    
    func generateQRCode() {
        let data = card.getCardURL().data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = outputImage.transformed(by: transform)
                
                // Create a new context with a transparent background
                let context = CIContext()
                let bounds = scaledImage.extent
                if let cgImage = context.createCGImage(scaledImage, from: bounds) {
                    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
                    if let context = UIGraphicsGetCurrentContext() {
                        context.setFillColor(UIColor.clear.cgColor)
                        context.fill(bounds)
                        context.draw(cgImage, in: bounds)
                        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                            self.qrCode = newImage
                        }
                    }
                    UIGraphicsEndImageContext()
                }
            }
        }
    }
    
    func shareQRCode() {
        guard let qrCodeImage = qrCode else { return }
        
        let imageToShare: UIImage
        if selectedFormat == .jpeg {
            // Convert to JPEG (which doesn't support transparency)
            imageToShare = qrCodeImage.jpegData(compressionQuality: 1.0)
                .flatMap(UIImage.init) ?? qrCodeImage
        } else {
            // For PNG, use the existing image (with or without background)
            if noBackground {
                imageToShare = qrCodeImage
            } else {
                UIGraphicsBeginImageContextWithOptions(qrCodeImage.size, true, 0)
                UIColor.white.setFill()
                UIRectFill(CGRect(origin: .zero, size: qrCodeImage.size))
                qrCodeImage.draw(in: CGRect(origin: .zero, size: qrCodeImage.size))
                imageToShare = UIGraphicsGetImageFromCurrentImageContext() ?? qrCodeImage
                UIGraphicsEndImageContext()
            }
        }
        
        // Check photo library permission
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    UIImageWriteToSavedPhotosAlbum(imageToShare, nil, nil, nil)
                    // Show a success message
                    self.showAlert(title: "Success", message: "QR Code saved to your photo library.")
                } else {
                    // Show an error message
                    self.showAlert(title: "Error", message: "Unable to save QR Code. Please allow access to your photo library in Settings.")
                }
            }
        }
        
        let activityViewController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            // Present the activity view controller over the current sheet
            rootViewController.presentedViewController?.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.presentedViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
