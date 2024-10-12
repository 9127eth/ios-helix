//
//  ShareView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI

struct ShareView: View {
    let card: BusinessCard
    @Binding var isPresented: Bool
    @State private var qrCode: UIImage?
    @State private var selectedFormat: String = "PNG"
    @State private var noBackground: Bool = false
    
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
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy URL")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(AppColors.primary)
                                .foregroundColor(AppColors.primaryText)
                                .cornerRadius(20)
                            }
                            .frame(width: 320)
                            
                            Button(action: {
                                if let url = URL(string: card.getCardURL()) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "safari")
                                    Text("View in Browser")
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
                            
                            HStack {
                                Picker("Format", selection: $selectedFormat) {
                                    Text("PNG").tag("PNG")
                                    Text("JPEG").tag("JPEG")
                                    Text("SVG").tag("SVG")
                                }
                                .pickerStyle(MenuPickerStyle())
                                
                                Toggle("No background", isOn: $noBackground)
                            }
                            
                            Button(action: downloadQRCode) {
                                HStack {
                                    Image(systemName: "qrcode")
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
    
    func downloadQRCode() {
        // Implement QR code download functionality here
        // This would typically involve generating the QR code in the selected format
        // and saving it to the device or sharing it via a share sheet
    }
}
