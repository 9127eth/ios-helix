import SwiftUI
import PassKit

class AddToWalletViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: WalletError?
    
    func addToWallet(card: BusinessCard) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let pass = try await WalletManager.shared.createPass(for: card)
            
            await MainActor.run {
                let passLibrary = PKPassLibrary()
                if !passLibrary.containsPass(pass) {
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
                } else {
                    self.error = .duplicatePass
                }
            }
        } catch {
            print("Pass creation error: \(error)")
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
} 