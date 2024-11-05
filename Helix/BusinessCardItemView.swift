//
//  BusinessCardItemView.swift
//  Helix
//
//  Created by Richard Waithe on 10/11/24.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import NotificationCenter
import CoreNFC

struct BusinessCardItemView: View {
    @Binding var card: BusinessCard
    let username: String
    @State private var showPreview = false
    @State private var showShare = false
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    @State private var offset: CGFloat = 0
    @State private var showingActionButtons = false
    @State private var actionButtonsOpacity: Double = 0 // Add this line
    @StateObject private var nfcWriter = NFCWriter()
    @State private var showColorPicker = false
    @State private var selectedColor: Color = AppColors.cardDepthDefault
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Spacer()
                    actionButtons
                        .frame(width: 220, height: geometry.size.height)
                        .offset(x: offset + 220)
                        .opacity(actionButtonsOpacity) // Add this line
                }
                .frame(height: geometry.size.height, alignment: .center)
            }
            
            cardContent
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { gesture in
                            if abs(gesture.translation.width) > abs(gesture.translation.height) {
                                offset = min(0, gesture.translation.width)
                                // Gradually increase opacity as user swipes
                                actionButtonsOpacity = Double(-offset / 220)
                            }
                        }
                        .onEnded { gesture in
                            withAnimation {
                                if gesture.translation.width < -50 && abs(gesture.translation.width) > abs(gesture.translation.height) {
                                    offset = -220
                                    showingActionButtons = true
                                    actionButtonsOpacity = 1 // Fully visible
                                } else {
                                    offset = 0
                                    showingActionButtons = false
                                    actionButtonsOpacity = 0 // Fully hidden
                                }
                            }
                        }
                )
        }
        .sheet(isPresented: $showPreview) {
            PreviewView(card: card, username: username, isPresented: $showPreview)
        }
        .sheet(isPresented: $showShare) {
            ShareView(card: card, username: username, isPresented: $showShare)
        }
        .sheet(isPresented: $showingEditView) {
            EditBusinessCardView(businessCard: $card, username: username)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerView(selectedColor: $selectedColor, card: $card)
                .presentationDetents([.fraction(0.30)])
        }
        .alert("Confirm Deletion", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCard()
            }
        } message: {
            Text("Are you sure you want to delete this business card? This action cannot be undone.")
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            actionButton(title: "Edit", action: { showingEditView = true })
            actionButton(title: "Preview", action: { showPreview = true })
            actionButton(title: "Share", action: { showShare = true })
        }
        .padding(.vertical, 20)
    }
    
    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.buttonText)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(AppColors.secondary)
                .cornerRadius(12)
        }
        .frame(width: 160)
    }
    
    private var cardContent: some View {
        ZStack {
            // Background shadow layer for depth effect
            RoundedRectangle(cornerRadius: 20)
                .fill(card.cardDepthColor != nil ? Color(hex: card.cardDepthColor!) : AppColors.cardDepthDefault)
                .offset(x: 8, y: 8) // Offset to create depth effect
            
            // Main card content
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(card.description)
                        .font(.system(size: 30))
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(AppColors.bodyPrimaryText)
                        .onTapGesture {
                            if card.isActive {
                                showShare = true
                            }
                        }
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            showPreview = true
                        } label: {
                            Label {
                                Text("Preview")
                            } icon: {
                                Image("previewCard")
                            }
                        }
                        Button {
                            showShare = true
                        } label: {
                            Label {
                                Text("Share")
                            } icon: {
                                Image("share.3")
                            }
                        }
                        Button {
                            showingEditView = true
                        } label: {
                            Label {
                                Text("Edit")
                            } icon: {
                                Image("pencilEdit")
                            }
                        }
                        Button {
                            addToNFC()
                        } label: {
                            Label {
                                Text("Add to NFC")
                            } icon: {
                                Image("nfc")
                            }
                        }
                        Button {
                            showColorPicker = true
                        } label: {
                            Label {
                                Text("Change Color")
                            } icon: {
                                Image(systemName: "paintpalette")
                            }
                        }
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label {
                                Text("Delete")
                            } icon: {
                                Image("trashDelete")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(AppColors.bodyPrimaryText)
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                            .frame(width: 44, height: 30) // Increase the frame size
                            .contentShape(Rectangle()) // Make the entire frame tappable
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove default button styling
                }
                
                // New section for name and credentials
                Text(buildNameAndCredentials())
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                    .lineLimit(1)
                
                if let jobTitle = card.jobTitle {
                    Text(jobTitle)
                        .font(.subheadline)
                        .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                        .lineLimit(1)
                }
                
                if let company = card.company {
                    Text(company)
                        .font(.subheadline)
                        .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Divider()
                    .background(AppColors.divider)
                
                // Bottom section with buttons
                HStack {
                    // Status indicators section with share tap area
                    HStack(spacing: 4) {
                        VStack(alignment: .leading) {
                            HStack(spacing: 4) {
                                if card.isPrimary {
                                    Text("Main")
                                        .font(.caption)
                                        .foregroundColor(Color.gray)
                                }
                                if !card.isActive {
                                    Text("Inactive")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(Color.gray)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        // Make sure there's always a tappable area, even if no status indicators are shown
                        Color.clear
                            .frame(height: 20)
                    }
                    .frame(width: 120) // Set a fixed width for the tappable area
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                if card.isActive {
                                    showShare = true
                                }
                            }
                    )
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: { showingEditView = true }) {
                            Image("pencilEdit")
                                .frame(width: 30, height: 30)
                        }
                        Button(action: { showPreview = true }) {
                            Image("previewCard")
                                .frame(width: 30, height: 30)
                        }
                        Button(action: { showShare = true }) {
                            Image("share.3")
                                .frame(width: 30, height: 30)
                        }
                        .disabled(!card.isActive)
                    }
                    .foregroundColor(colorScheme == .dark ? Color(hex: 0xdddee3) : .black)
                    .font(.system(size: 18))
                }
            }
            .padding()
            .frame(height: 200)
            .background(AppColors.cardGridBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: 0xe5e6ed), lineWidth: 1)
                    .opacity(colorScheme == .dark ? 1 : 0)
            )
        }
        .frame(height: 200)
    }
    
    private func deleteCard() {
        Task {
            do {
                try await BusinessCard.delete(card)
                print("Card deleted successfully")
                // Notify the parent view that a card was deleted
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .cardDeleted, object: nil)
                }
            } catch {
                print("Error deleting card: \(error.localizedDescription)")
                // Here you might want to show an error alert to the user
            }
        }
    }
    
    private func addToNFC() {
        guard let url = URL(string: card.getCardURL(username: username)) else {
            print("Error: Invalid URL for NFC tag")
            return
        }
        
        DispatchQueue.main.async {
            self.nfcWriter.writeToNFC(url: url)
        }
    }
    
    private func buildNameAndCredentials() -> AttributedString {
        var result = AttributedString(card.firstName)
        result.font = .system(size: 14).bold()

        if let lastName = card.lastName {
            result += AttributedString(" \(lastName)")
            result[result.range(of: lastName)!].font = .system(size: 14).bold()
        }

        if let credentials = card.credentials, !credentials.isEmpty {
            result += AttributedString(", \(credentials)")
            let credentialsRange = result.range(of: ", \(credentials)")!
            result[credentialsRange].font = .system(size: 14)
        }

        return result
    }
}

class NFCWriter: NSObject, NFCNDEFReaderSessionDelegate, ObservableObject {
    @Published var isWriting: Bool = false
    @Published var lastWriteResult: String?

    var session: NFCNDEFReaderSession?
    var urlToWrite: URL?

    func writeToNFC(url: URL) {
        print("writeToNFC called with URL: \(url)")
        self.urlToWrite = url
        self.isWriting = true
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the NFC tag to write your business card URL."
        session?.begin()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Not used for writing
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        print("didDetect tags called")
        guard let tag = tags.first, let url = urlToWrite else { 
            session.invalidate()
            return 
        }
        
        session.connect(to: tag) { error in
            if error != nil {
                session.invalidate()
                return
            }

            tag.queryNDEFStatus { status, _, _ in
                switch status {
                case .notSupported, .readOnly:
                    session.invalidate()
                case .readWrite:
                    let payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url)!
                    let message = NFCNDEFMessage(records: [payload])
                    tag.writeNDEF(message) { error in
                        if error != nil {
                            self.updateWriteResult("Write failed: \(error!.localizedDescription)")
                            session.invalidate()
                        } else {
                            self.updateWriteResult("Success")
                            session.alertMessage = "Success"
                            session.invalidate()
                        }
                    }
                @unknown default:
                    session.invalidate()
                }
            }
        }
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Not needed for writing
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("Session invalidated with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isWriting = false
            self.lastWriteResult = error.localizedDescription
        }
    }

    // Add this method to update the write result
    private func updateWriteResult(_ result: String) {
        DispatchQueue.main.async {
            self.isWriting = false
            self.lastWriteResult = result
        }
    }
}

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(format: "#%02X%02X%02X",
                     Int(red * 255),
                     Int(green * 255),
                     Int(blue * 255))
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

