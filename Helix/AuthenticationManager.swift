//
//  AuthenticationManager.swift
//  Helix
//
//  Created by Richard Waithe on 10/9/24.
//

import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class AuthenticationManager: NSObject, ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    private var appleSignInCompletion: ((Result<User, Error>) -> Void)?
    private var currentNonce: String?

    override init() {
        super.init()
        setupFirebaseAuthStateListener()
    }
    
    private func setupFirebaseAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                print("Authentication state changed. isAuthenticated: \(self?.isAuthenticated ?? false)")
            }
        }
    }
    
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        print("Attempting to sign in with email: \(email)")
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let user = authResult?.user {
                print("Sign in successful for user: \(user.uid)")
                completion(.success(user))
            } else if let error = error {
                print("Sign in failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func signUpWithEmail(email: String, password: String) async throws -> User {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = authResult.user
        try await createUserDocument(for: user)
        return user
    }
    
    func signInWithGoogle(presenting viewController: UIViewController) async throws -> User {
        guard let clientID = getGoogleClientID() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve Google Client ID"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token from Google Sign In"])
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        let user = authResult.user
        
        try await createUserDocument(for: user)
        return user
    }
    
    func signInWithApple() async throws -> User {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let result = try await withCheckedThrowingContinuation { continuation in
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = AppleSignInDelegate(continuation: continuation)
            authorizationController.performRequests()
        }
        
        guard let appleIDCredential = result as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])
        }
        
        guard let nonce = currentNonce else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."])
        }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        let user = authResult.user
        
        try await createUserDocument(for: user)
        return user
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    // Helper functions for Apple Sign In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func getGoogleClientID() -> String? {
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let clientID = plist["CLIENT_ID"] as? String else {
            print("Failed to retrieve Google Client ID from GoogleService-Info.plist")
            return nil
        }
        return clientID
    }
    
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func createUserDocument(for user: User) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        let document = try await userRef.getDocument()
        
        if document.exists {
            // User document already exists, no need to create
            return
        } else {
            // User document doesn't exist, create it
            let username = try await generateUniqueUsername()
            
            let userData: [String: Any] = [
                "createdAt": FieldValue.serverTimestamp(),
                "isPro": false,
                "primaryCardId": username,  // Set primaryCardId to the username
                "primaryCardPlaceholder": true,
                "stripeCustomerId": "",
                "stripeSubscriptionId": "",
                "updatedAt": FieldValue.serverTimestamp(),
                "username": username
            ]
            
            try await userRef.setData(userData)
        }
    }

    private func generateUniqueUsername() async throws -> String {
        let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
        let blacklist = ["nig", "fag", "ass", "sex", "fat", "gay"]
        var username: String
        var attempts = 0
        let maxAttempts = 10

        repeat {
            username = String((0..<6).map { _ in characters.randomElement()! })
            attempts += 1
            if attempts >= maxAttempts {
                throw NSError(domain: "com.helix.error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to generate a unique username after \(maxAttempts) attempts"])
            }
        } while !(try await isUsernameUnique(username)) || containsBlacklistedWord(username, blacklist: blacklist)

        return username
    }

    private func isUsernameUnique(_ username: String) async -> Bool {
        let db = Firestore.firestore()
        do {
            let querySnapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username)
                .limit(to: 1)
                .getDocuments()
            
            return querySnapshot.documents.isEmpty
        } catch {
            print("Error checking username uniqueness: \(error)")
            return false
        }
    }

    private func containsBlacklistedWord(_ username: String, blacklist: [String]) -> Bool {
        return blacklist.contains { username.contains($0) }
    }

    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }

        // Delete user data from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { error in
            if let error = error {
                print("Error deleting user data: \(error.localizedDescription)")
                // Continue with account deletion even if Firestore deletion fails
            }

            // Delete the user account
            user.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self.signOut() // Sign out after successful deletion
                    completion(.success(()))
                }
            }
        }
    }
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let user = authResult?.user {
                    Task {
                        do {
                            try await self?.createUserDocument(for: user)
                            self?.appleSignInCompletion?(.success(user))
                        } catch {
                            self?.appleSignInCompletion?(.failure(error))
                        }
                    }
                } else if let error = error {
                    self?.appleSignInCompletion?(.failure(error))
                }
                self?.appleSignInCompletion = nil
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
        self.appleSignInCompletion?(.failure(error))
        self.appleSignInCompletion = nil
    }
}

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
}

// Helper class for Apple Sign In
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<ASAuthorization, Error>
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}
