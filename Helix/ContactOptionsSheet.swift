import SwiftUI

struct ContactOptionsSheet: View {
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if let phone = contact.phone {
                    Button(action: { 
                        callPhone(phone)
                        dismiss()
                    }) {
                        Label("Call", systemImage: "phone")
                            .padding(.vertical, 8)
                    }
                    
                    Button(action: { 
                        sendText(phone)
                        dismiss()
                    }) {
                        Label("Text Message", systemImage: "message")
                            .padding(.vertical, 8)
                    }
                }
                
                if let email = contact.email {
                    Button(action: { 
                        sendEmail(email)
                        dismiss()
                    }) {
                        Label("Email", systemImage: "envelope")
                            .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func callPhone(_ number: String) {
        if let url = URL(string: "tel://\(number)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendText(_ number: String) {
        // Step 1: Remove spaces and special characters
        let noSpaces = number.replacingOccurrences(of: " ", with: "")
        let noHyphens = noSpaces.replacingOccurrences(of: "-", with: "")
        let noParens = noHyphens.replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Step 2: Clean up
        let cleaned = noParens.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Step 3: Create and open URL
        if let url = URL(string: "sms:\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
} 