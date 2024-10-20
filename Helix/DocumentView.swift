//
//  DocumentView.swift
//  Helix
//
//  Created by Richard Waithe on 10/14/24.
//

import SwiftUI
import FirebaseStorage
import FirebaseAuth
import UniformTypeIdentifiers

struct DocumentView: View {
    @Binding var businessCard: BusinessCard
    @State private var isDocumentPickerPresented = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var uploadError: String?
    @FocusState private var focusedField: Field?
    @State private var showSubscriptionView = false
    var showHeader: Bool
    var isPro: Bool
    
    enum Field: Hashable {
        case cvHeader, cvDescription, cvDisplayText
    }
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true, isPro: Bool = false) {
        self._businessCard = businessCard
        self.showHeader = showHeader
        self.isPro = isPro
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Document")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            Text("Upload your CV/resume, a study, a menu, schedule, or any other document to your business card. It must be a PDF and max file size is 5MB.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            HStack {
                Button(action: { 
                    if isPro {
                        isDocumentPickerPresented = true
                    } else {
                        showSubscriptionView = true
                    }
                }) {
                    Text(isPro ? "Choose File" : "Upgrade")
                        .foregroundColor(AppColors.buttonText)
                        .font(.system(size: UIFont.labelFontSize * 0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(width: 120) // Set a fixed width
                        .background(AppColors.buttonBackground)
                        .cornerRadius(16)
                }
                .disabled(isUploading)
                
                if !isPro {
                    Text("Get Helix Pro to add a document")
                        .foregroundColor(.gray)
                        .font(.system(size: UIFont.labelFontSize * 0.8))
                        .padding(.leading, 8)
                }
            }
            
            if !isPro {
                Button(action: {}) {
                    Text(businessCard.cvUrl == nil ? "Choose File" : "Replace Document")
                        .foregroundColor(.gray)
                        .font(.system(size: UIFont.labelFontSize * 0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(width: 120) // Set the same fixed width
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(16)
                }
                .disabled(true)
                .padding(.top, 2)
            }
            
            if let cvUrl = businessCard.cvUrl {
                Text("Document uploaded: \(cvUrl)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            CustomTextField(title: "Header", text: Binding(
                get: { businessCard.cvHeader ?? "" },
                set: { businessCard.cvHeader = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = .cvDescription })
                .focused($focusedField, equals: .cvHeader)
                .disabled(!isPro)
                .opacity(isPro ? 1 : 0.6)
            
            CustomTextField(title: "Description", text: Binding(
                get: { businessCard.cvDescription ?? "" },
                set: { businessCard.cvDescription = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = .cvDisplayText })
                .focused($focusedField, equals: .cvDescription)
                .disabled(!isPro)
                .opacity(isPro ? 1 : 0.6)
            
            CustomTextField(title: "File Name Display Text (Optional)", text: Binding(
                get: { businessCard.cvDisplayText ?? "" },
                set: { businessCard.cvDisplayText = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = nil })
                .focused($focusedField, equals: .cvDisplayText)
                .disabled(!isPro)
                .opacity(isPro ? 1 : 0.6)
            
            if isUploading {
                ProgressView(value: uploadProgress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            if let error = uploadError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.top, showHeader ? 0 : 16)
        .fileImporter(
            isPresented: $isDocumentPickerPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    uploadDocument(file)
                }
            case .failure(let error):
                print("Error selecting document: \(error.localizedDescription)")
                uploadError = "Error selecting document. Please try again."
            }
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView(isPro: .constant(false))
        }
    }
    
    private func uploadDocument(_ file: URL) {
        guard let userId = Auth.auth().currentUser?.uid else {
            uploadError = "User not authenticated"
            return
        }
        
        isUploading = true
        uploadProgress = 0
        uploadError = nil
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let documentName = "\(UUID().uuidString).pdf"
        let documentRef = storageRef.child("documents/\(userId)/\(documentName)")
        
        let uploadTask = documentRef.putFile(from: file, metadata: nil) { metadata, error in
            isUploading = false
            
            if let error = error {
                print("Error uploading document: \(error.localizedDescription)")
                uploadError = "Error uploading document. Please try again."
                return
            }
            
            documentRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    uploadError = "Error getting download URL. Please try again."
                    return
                }
                
                if let downloadURL = url {
                    businessCard.cvUrl = downloadURL.absoluteString
                    print("Document uploaded successfully. URL: \(downloadURL.absoluteString)")
                }
            }
        }
        
        uploadTask.observe(.progress) { snapshot in
            uploadProgress = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
        }
    }
}
