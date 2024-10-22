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
import FirebaseFirestore

struct DocumentView: View {
    @Binding var businessCard: BusinessCard
    @State private var isDocumentPickerPresented = false
    @State private var uploadError: String?
    @Binding var selectedDocument: URL?
    @State private var showSubscriptionView = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @FocusState private var focusedField: Field?
    var showHeader: Bool
    @Binding var isPro: Bool

    enum Field: Hashable {
        case cvHeader, cvDescription, cvDisplayText
    }

    init(
        businessCard: Binding<BusinessCard>,
        showHeader: Bool = true,
        isPro: Binding<Bool>,
        selectedDocument: Binding<URL?> // Added parameter
    ) {
        self._businessCard = businessCard
        self.showHeader = showHeader
        self._isPro = isPro
        self._selectedDocument = selectedDocument // Initialize the binding
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
                // "Choose File" button is always visible
                Button(action: { 
                    isDocumentPickerPresented = true
                }) {
                    Text("Choose File")
                        .foregroundColor($isPro.wrappedValue ? AppColors.buttonText : .gray)
                        .font(.system(size: UIFont.labelFontSize * 0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(width: 120)
                        .background($isPro.wrappedValue ? AppColors.buttonBackground : Color.gray.opacity(0.3))
                        .cornerRadius(16)
                }
                .disabled(!$isPro.wrappedValue)
                
                // "Upgrade" button for non-pro users
                if !$isPro.wrappedValue {
                    Button(action: {
                        showSubscriptionView = true
                    }) {
                        Text("Upgrade")
                            .foregroundColor(AppColors.buttonText)
                            .font(.system(size: UIFont.labelFontSize * 0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .frame(width: 120)
                            .background(AppColors.buttonBackground)
                            .cornerRadius(16)
                    }
                }
            }
            
            // Helix Pro message for non-pro users
            if !$isPro.wrappedValue {
                Text("Upgrade to Helix Pro to add a document")
                    .foregroundColor(.foreground)
                    .font(.system(size: UIFont.labelFontSize * 0.8))
                    .padding(.leading, 8)
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
                .disabled(!$isPro.wrappedValue)
                .opacity($isPro.wrappedValue ? 1 : 0.6)
            
            CustomTextField(title: "Description", text: Binding(
                get: { businessCard.cvDescription ?? "" },
                set: { businessCard.cvDescription = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = .cvDisplayText })
                .focused($focusedField, equals: .cvDescription)
                .disabled(!$isPro.wrappedValue)
                .opacity($isPro.wrappedValue ? 1 : 0.6)
            
            CustomTextField(title: "File Name Display Text (Optional)", text: Binding(
                get: { businessCard.cvDisplayText ?? "" },
                set: { businessCard.cvDisplayText = $0.isEmpty ? nil : $0 }
            ), onCommit: { focusedField = nil })
                .focused($focusedField, equals: .cvDisplayText)
                .disabled(!$isPro.wrappedValue)
                .opacity($isPro.wrappedValue ? 1 : 0.6)
            
            if let error = uploadError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if let selectedDoc = selectedDocument {
                Text("Selected document: \(selectedDoc.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.gray)
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
                    selectedDocument = file
                    uploadError = nil
                }
            case .failure(let error):
                print("Error selecting document: \(error.localizedDescription)")
                uploadError = "Error selecting document. Please try again."
            }
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView(isPro: $isPro)
        }
        .onAppear {
            listenToProStatus()
        }
    }

    private func listenToProStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                let newIsPro = document.data()?["isPro"] as? Bool ?? false
                DispatchQueue.main.async {
                    self.isPro = newIsPro
                }
            }
    }
}
