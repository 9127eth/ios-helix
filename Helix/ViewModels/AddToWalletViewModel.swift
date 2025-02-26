import SwiftUI
import PassKit

class AddToWalletViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: WalletError?
    @Published var passExists = false
    
    // Check if a pass exists - simplified to just check existence
    func checkPassStatus(for card: BusinessCard) {
        let walletManager = WalletManager.shared
        passExists = walletManager.passExists(for: card)
    }
    
    func addToWallet(card: BusinessCard) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let walletManager = WalletManager.shared
            let passExists = walletManager.passExists(for: card)
            
            let pass: PKPass
            
            if passExists {
                // Update existing pass
                pass = try await walletManager.updatePass(for: card)
            } else {
                // Create new pass
                pass = try await walletManager.createPass(for: card)
            }
            
            await MainActor.run {
                // Always use PKAddPassesViewController for both new and updated passes
                presentAddPassViewController(pass: pass)
                
                // Update status after operation
                self.checkPassStatus(for: card)
            }
        } catch {
            print("Pass creation/update error: \(error)")
            await MainActor.run {
                if let walletError = error as? WalletError {
                    self.error = walletError
                } else {
                    self.error = .passCreationFailed
                }
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func presentAddPassViewController(pass: PKPass) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            self.error = .passCreationFailed
            return
        }
        
        let addPassViewController = PKAddPassesViewController(pass: pass)
        if let presenter = addPassViewController {
            viewController.present(presenter, animated: true)
        } else {
            self.error = .passCreationFailed
        }
    }
} 