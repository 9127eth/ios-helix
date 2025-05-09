//
//  ShareView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI
import Photos
import SafariServices

struct ShareView: View {
    let card: BusinessCard
    let username: String
    @Binding var isPresented: Bool
    @State private var qrCode: UIImage?
    @State private var selectedFormat: ImageFormat = .png
    @State private var noBackground: Bool = false
    @State private var showCopiedCheckmark = false
    @State private var showPreview = false
    
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
                    
                    VStack(alignment: .leading, spacing: 5) {
                        if let jobTitle = card.jobTitle {
                            Text(jobTitle)
                                .font(.system(size: 20))
                                .foregroundColor(.bodyPrimaryText)
                                .lineLimit(1)
                        }
                        
                        if let company = card.company {
                            Text(company)
                                .font(.system(size: 20))
                                .foregroundColor(.gray.opacity(0.8))
                                .lineLimit(2)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    VStack(alignment: .center, spacing: 30) {
                        if let qrCode = qrCode {
                            Image(uiImage: qrCode)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        
                        Text(card.getCardURL(username: username))
                            .font(.caption)
                        
                        // Single Share Link button
                        Button(action: {
                            let url = card.getCardURL(username: username)
                            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootViewController = window.rootViewController {
                                rootViewController.presentedViewController?.present(activityViewController, animated: true, completion: nil)
                            }
                        }) {
                            HStack {
                                Image("share.3")
                                Text("Share Link")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppColors.primary)
                            .foregroundColor(.black)
                            .cornerRadius(22)
                        }
                        .frame(width: 200)
                        
                        Divider()
                            .background(Color.gray.opacity(0.5))
                            .padding(.vertical, 10)
                        
                        // New List
                        VStack(spacing: 0) {
                            Button(action: {
                                UIPasteboard.general.string = card.getCardURL(username: username)
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
                                    Image(showCopiedCheckmark ? "clipboardCheck" : "Copyplus2")
                                    Text(showCopiedCheckmark ? "Copied!" : "Copy Link")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.foreground)
                                    Spacer()
                                }
                                .padding()
                                .background(AppColors.inputFieldBackground)
                            }
                            
                            Button(action: {
                                showPreview = true
                            }) {
                                HStack {
                                    Image("browser")
                                    Text("View in Browser")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.foreground)
                                    Spacer()
                                }
                                .padding()
                                .background(AppColors.inputFieldBackground)
                            }
                            .sheet(isPresented: $showPreview) {
                                PreviewView(card: card, username: username, isPresented: $showPreview)
                            }
                            
                            DisclosureGroup {
                                VStack(spacing: 20) {
                                    Picker("Select Format", selection: $selectedFormat) {
                                        ForEach(ImageFormat.allCases, id: \.self) { format in
                                            Text(format.rawValue).tag(format)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                    
                                    if selectedFormat == .png {
                                        Toggle("Transparent background", isOn: $noBackground)
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.foreground)
                                            .padding(.horizontal)
                                    }
                                    
                                    Button(action: shareQRCode) {
                                        HStack {
                                            Image("share.3")
                                            Text("Share QR Code")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(AppColors.secondary)
                                        .foregroundColor(AppColors.buttonText)
                                        .cornerRadius(20)
                                    }
                                    .frame(width: 200)
                                    .padding(.bottom, 20)
                                }
                            } label: {
                                HStack {
                                    Image("qrcode")
                                    Text("Share QR Code Image")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.foreground)
                                    Spacer()
                                }
                                .padding()
                                .background(AppColors.inputFieldBackground)
                            }
                            .padding(.trailing, 12)
                        }
                        .padding(.bottom, 8)
                        .background(AppColors.inputFieldBackground)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationBarItems(trailing: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
                    .font(.system(size: 20, weight: .bold))
            })
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .background(AppColors.background.edgesIgnoringSafeArea(.all))
        .onAppear(perform: generateQRCode)
    }
    
    func generateQRCode() {
        let data = card.getCardURL(username: username).data(using: .ascii)
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
        
        let activityViewController = UIActivityViewController(activityItems: [imageToShare, card.getCardURL(username: username)], applicationActivities: nil)
        
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
