import PassKit
import UIKit
import Foundation
import CommonCrypto
import ZipArchive
import CommonCrypto
import Security
import Firebase
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore

enum WalletError: Error, LocalizedError {
    case passCreationFailed
    case templateNotFound
    case certificateNotFound
    case invalidCertificate
    case signingFailed
    case duplicatePass
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .passCreationFailed:
            return "Failed to create the pass for Apple Wallet."
        case .templateNotFound:
            return "Pass template not found."
        case .certificateNotFound:
            return "Pass certificate not found."
        case .invalidCertificate:
            return "Invalid certificate for signing the pass."
        case .signingFailed:
            return "Failed to sign the pass."
        case .duplicatePass:
            return "This card is already in your Apple Wallet."
        case .userCancelled:
            return "Adding to wallet was cancelled."
        }
    }
}

class WalletManager {
    static let shared = WalletManager()
    
    private let passTypeIdentifier: String
    private let teamIdentifier: String
    private let certificatePassword: String
    
    private init() {
        // Get configuration from Info.plist
        guard let passTypeIdentifier = Bundle.main.infoDictionary?["WALLET_PASS_TYPE_IDENTIFIER"] as? String,
              let teamIdentifier = Bundle.main.infoDictionary?["WALLET_TEAM_IDENTIFIER"] as? String,
              let certificatePassword = Bundle.main.infoDictionary?["WALLET_CERTIFICATE_PASSWORD"] as? String else {
            fatalError("Wallet configuration missing from Info.plist")
        }
        
        self.passTypeIdentifier = passTypeIdentifier
        self.teamIdentifier = teamIdentifier
        self.certificatePassword = certificatePassword
        
        print("WalletManager initialized with passTypeIdentifier: \(passTypeIdentifier)")
    }
    
    func createPass(for card: BusinessCard) async throws -> PKPass {
        print("Starting pass creation for card: \(card.firstName) \(card.lastName ?? "")")
        
        // Fetch the username from Firebase
        let username = await fetchUsernameFromFirebase()
        print("Using username for card URL: \(username)")
        
        // Create URL for the function
        let functionURL = URL(string: "https://us-central1-helixcardapp.cloudfunctions.net/generatePassV2")!
        
        // Create URL request
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("helix-wallet-api-key-12345", forHTTPHeaderField: "X-API-Key") // Use the same API key as in the function
        
        // Create request body
        let body: [String: Any] = [
            "firstName": card.firstName,
            "lastName": card.lastName ?? "",
            "company": card.company ?? "",
            "jobTitle": card.jobTitle ?? "",
            "cardSlug": card.cardSlug,
            "cardURL": card.getCardURL(username: username),
            "description": card.description,
            "phoneNumber": card.phoneNumber ?? "",
            "email": card.email ?? "",
            "imageUrl": card.imageUrl ?? ""
        ]
        
        // Set the request body
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Sending HTTP request to function for: \(card.firstName) \(card.lastName ?? "")")
        
        // Send the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response type")
            throw WalletError.passCreationFailed
        }
        
        print("Received response with status code: \(httpResponse.statusCode)")
        
        // Check for successful status code
        guard httpResponse.statusCode == 200 else {
            print("Response headers: \(httpResponse.allHeaderFields)")
            
            let errorString = String(data: data, encoding: .utf8)
            if let errorString = errorString {
                print("Error response body: \(errorString)")
            }
            
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Error JSON: \(errorJson)")
                if let errorMessage = errorJson["details"] as? String {
                    print("Function returned error: \(errorMessage)")
                }
            } else {
                print("Function returned error with status code: \(httpResponse.statusCode)")
            }
            throw WalletError.passCreationFailed
        }
        
        // Create PKPass from response data
        do {
            let pkPass = try PKPass(data: data)
            print("Successfully created PKPass object")
            return pkPass
        } catch {
            print("Error creating PKPass: \(error.localizedDescription)")
            throw WalletError.passCreationFailed
        }
    }
    
    private func signPass(at passDirectory: URL) async throws -> PKPass {
        print("Starting pass signing process")
        
        // 1. Find the certificate in the bundle
        guard let certificateURL = Bundle.main.url(forResource: "pass.com.rxradio.helix", withExtension: "p12") else {
            print("Error: Certificate file not found in bundle")
            throw WalletError.certificateNotFound
        }
        
        print("Found certificate at: \(certificateURL.path)")
        
        // 2. Load the certificate data
        let certificateData = try Data(contentsOf: certificateURL)
        
        print("Loaded certificate data: \(certificateData.count) bytes")
        
        // 3. Create a pass signer
        let passURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            do {
                // Create the manifest.json file
                try createManifest(in: passDirectory)
                
                print("Created manifest.json")
                
                // Sign the manifest to create signature file
                try signManifest(in: passDirectory, with: certificateData, password: certificatePassword)
                
                print("Signed manifest and created signature file")
                
                // Create the final .pkpass file
                let passURL = try createFinalPass(from: passDirectory)
                
                print("Created final .pkpass file at: \(passURL.path)")
                
                continuation.resume(returning: passURL)
            } catch {
                print("Error during pass signing: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
        
        // 4. Create PKPass from the signed pass
        do {
            let passData = try Data(contentsOf: passURL)
            let pkPass = try PKPass(data: passData)
            
            print("Successfully created PKPass object")
            
            // Clean up the temporary .pkpass file
            try? FileManager.default.removeItem(at: passURL)
            
            return pkPass
        } catch {
            print("Error creating PKPass: \(error.localizedDescription)")
            throw WalletError.passCreationFailed
        }
    }
    
    private func createManifest(in passDirectory: URL) throws {
        print("Creating manifest.json")
        
        var manifestDict = [String: Any]()
        let fileManager = FileManager.default
        
        // Get all files in the pass directory
        let contents = try fileManager.contentsOfDirectory(at: passDirectory, includingPropertiesForKeys: nil)
        
        // Calculate SHA1 hash for each file
        for fileURL in contents {
            let fileName = fileURL.lastPathComponent
            
            // Skip manifest and signature files
            if fileName == "manifest.json" || fileName == "signature" {
                continue
            }
            
            let fileData = try Data(contentsOf: fileURL)
            let hash = SHA1.hash(data: fileData).compactMap { String(format: "%02x", $0) }.joined()
            
            manifestDict[fileName] = hash
            print("Added hash for \(fileName): \(hash)")
        }
        
        // Write manifest.json
        let manifestData = try JSONSerialization.data(withJSONObject: manifestDict)
        let manifestURL = passDirectory.appendingPathComponent("manifest.json")
        try manifestData.write(to: manifestURL)
        
        print("manifest.json created successfully")
    }
    
    private func signManifest(in passDirectory: URL, with certificateData: Data, password: String) throws {
        print("Signing manifest.json")
        
        // Load the manifest data
        let manifestURL = passDirectory.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        
        // Create a security identity from the certificate
        guard let identity = loadIdentity(from: certificateData, password: password) else {
            print("Error: Failed to load identity from certificate")
            throw WalletError.invalidCertificate
        }
        
        print("Loaded identity from certificate")
        
        // Extract the private key from the identity
        var privateKey: SecKey?
        let status1 = SecIdentityCopyPrivateKey(identity, &privateKey)
        
        guard status1 == errSecSuccess, let privateKey = privateKey else {
            print("Error: Could not get private key from identity: \(status1)")
            throw WalletError.signingFailed
        }
        
        // Get the certificate from the identity
        var certificate: SecCertificate?
        SecIdentityCopyCertificate(identity, &certificate)
        
        guard let certificate = certificate else {
            print("Error: Could not get certificate from identity")
            throw WalletError.invalidCertificate
        }
        
        // Create a signature using Apple's Wallet format
        guard let signature = createAppleWalletSignature(for: manifestData, 
                                                        using: privateKey, 
                                                        certificate: certificate) else {
            print("Error: Failed to create signature")
            throw WalletError.signingFailed
        }
        
        print("Created signature: \(signature.count) bytes")
        
        // Write the signature file
        let signatureURL = passDirectory.appendingPathComponent("signature")
        try signature.write(to: signatureURL)
        
        print("Signature file written successfully")
    }
    
    private func createAppleWalletSignature(for data: Data, using privateKey: SecKey, certificate: SecCertificate) -> Data? {
        print("Creating Apple Wallet signature")
        
        // 1. Create a SHA-1 hash of the data
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA1(buffer.baseAddress, CC_LONG(buffer.count), &digest)
        }
        
        print("Created SHA-1 hash of manifest data")
        
        // 2. Sign the hash with the private key
        let digestData = Data(digest)
        
        // Use SecKeyCreateSignature which is available on iOS
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA1,
            digestData as CFData,
            &error
        ) as Data? else {
            if let error = error?.takeRetainedValue() {
                print("Error creating signature: \(error)")
            }
            return nil
        }
        
        print("Created raw signature: \(signature.count) bytes")
        
        // For a proper implementation, we would need to create a PKCS#7 container
        // However, this is complex and requires additional libraries
        
        // For now, we'll use a workaround - create a simple DER-encoded structure
        // This is not a complete solution but might work for testing
        
        // Get the certificate data
        let certData = SecCertificateCopyData(certificate) as Data
        
        // Create a simple signature container
        var signatureContainer = Data()
        
        // Add some PKCS#7 header bytes (simplified)
        let header: [UInt8] = [0x30, 0x82]
        signatureContainer.append(contentsOf: header)
        
        // Add the certificate data
        signatureContainer.append(certData)
        
        // Add the signature
        signatureContainer.append(signature)
        
        print("Created signature container: \(signatureContainer.count) bytes")
        
        return signatureContainer
    }
    
    private func loadIdentity(from certificateData: Data, password: String) -> SecIdentity? {
        print("Loading identity from certificate")
        
        var identity: SecIdentity?
        
        // Import the PKCS12 data
        let options: [String: Any] = [kSecImportExportPassphrase as String: password]
        var items: CFArray?
        
        let status = SecPKCS12Import(certificateData as CFData, options as CFDictionary, &items)
        
        if status == errSecSuccess, let items = items, CFArrayGetCount(items) > 0 {
            let dictionary = CFArrayGetValueAtIndex(items, 0)
            let secIdentityDict = unsafeBitCast(dictionary, to: CFDictionary.self)
            
            if let identityRef = CFDictionaryGetValue(secIdentityDict, Unmanaged.passUnretained(kSecImportItemIdentity).toOpaque()) {
                identity = unsafeBitCast(identityRef, to: SecIdentity.self)
                print("Successfully loaded identity")
            }
        } else {
            print("Error importing certificate: \(status)")
        }
        
        return identity
    }
    
    private func createFinalPass(from passDirectory: URL) throws -> URL {
        print("Creating final .pkpass file")
        
        let passFileName = "\(UUID().uuidString).pkpass"
        let passURL = FileManager.default.temporaryDirectory.appendingPathComponent(passFileName)
        
        // Create a zip archive of the pass directory using FileManager
        // Instead of Process which isn't available in iOS
        if FileManager.default.fileExists(atPath: passURL.path) {
            try FileManager.default.removeItem(at: passURL)
        }
        
        // Use a third-party zip library or Apple's Archive framework
        // For this example, I'll use a simple implementation with ZipArchive
        if !createZipArchive(from: passDirectory, to: passURL) {
            print("Error: Failed to create zip archive")
            throw WalletError.passCreationFailed
        }
        
        print("Created .pkpass file at: \(passURL.path)")
        return passURL
    }
    
    // Helper method to create zip archive
    private func createZipArchive(from sourceDirectory: URL, to destinationURL: URL) -> Bool {
        print("Creating zip archive using SSZipArchive")
        
        // Use SSZipArchive to create the zip file
        let success = SSZipArchive.createZipFile(atPath: destinationURL.path, 
                                               withContentsOfDirectory: sourceDirectory.path)
        
        if success {
            print("Successfully created zip archive with SSZipArchive")
        } else {
            print("Failed to create zip archive with SSZipArchive")
        }
        
        return success
    }
    
    // Add a new method to fetch the username asynchronously
    private func fetchUsernameFromFirebase() async -> String {
        // Get the current user
        guard let currentUser = Auth.auth().currentUser else {
            print("Error: No authenticated user found")
            return "guest" // Fallback value
        }
        
        let uid = currentUser.uid
        
        do {
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(uid).getDocument()
            
            if let userData = userDoc.data(),
               let username = userData["username"] as? String {
                print("Retrieved username from Firebase: \(username)")
                return username
            } else {
                print("No username found in user document, using UID instead")
                return uid
            }
        } catch {
            print("Error fetching username from Firebase: \(error.localizedDescription)")
            return uid
        }
    }
    
    private func getUsernameFromFirebase() -> String? {
        // This method is kept for backward compatibility
        // But we should use fetchUsernameFromFirebase() for new code
        return Auth.auth().currentUser?.uid
    }
}

// SHA1 implementation for manifest hashing
struct SHA1 {
    static func hash(data: Data) -> [UInt8] {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA1(buffer.baseAddress, CC_LONG(buffer.count), &digest)
        }
        return digest
    }
}

