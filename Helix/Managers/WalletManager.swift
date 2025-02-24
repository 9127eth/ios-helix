import PassKit
import FirebaseFirestore
import CoreImage
import CoreImage.CIFilterBuiltins
import CryptoKit
import Security
import ZIPFoundation

class WalletManager {
    static let shared = WalletManager()
    private let passTypeIdentifier: String
    private let teamIdentifier: String
    private let certificatePassword: String
    private let certificatePath: String
    
    private init() {
        guard let passTypeId = Bundle.main.object(forInfoDictionaryKey: "WALLET_PASS_TYPE_IDENTIFIER") as? String,
              let teamId = Bundle.main.object(forInfoDictionaryKey: "WALLET_TEAM_IDENTIFIER") as? String,
              let certPassword = Bundle.main.object(forInfoDictionaryKey: "WALLET_CERTIFICATE_PASSWORD") as? String
        else {
            fatalError("Wallet configuration not found in Info.plist")
        }
        
        self.passTypeIdentifier = passTypeId
        self.teamIdentifier = teamId
        self.certificatePassword = certPassword
        
        let possiblePaths = [
            Bundle.main.path(forResource: passTypeId, ofType: "p12"),
            Bundle.main.path(forResource: passTypeId.replacingOccurrences(of: ".", with: ""), ofType: "p12"),
            Bundle.main.path(forResource: "Helix Pass Certificates", ofType: "p12", inDirectory: "Certificates"),
            Bundle.main.path(forResource: "Helix Pass Certificates", ofType: "p12")
        ].compactMap { $0 }
        
        guard let certPath = possiblePaths.first else {
            fatalError("Certificate not found. Tried paths: \(possiblePaths)")
        }
        
        print("Found certificate at path: \(certPath)")
        self.certificatePath = certPath
    }
    
    func createPass(for card: BusinessCard) async throws -> PKPass {
        print("Starting pass creation for card: \(card.cardSlug)")
        print("Using Pass Type ID: \(passTypeIdentifier)")
        print("Using Team ID: \(teamIdentifier)")
        
        guard let passURL = Bundle.main.url(forResource: "CardTemplate", withExtension: "pass") else {
            print("Failed to find CardTemplate.pass")
            throw WalletError.templateNotFound
        }
        print("Found template at: \(passURL)")
        
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let workingDirURL = temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workingDirURL, withIntermediateDirectories: true)
        print("Created working directory at: \(workingDirURL)")
        
        let enumerator = FileManager.default.enumerator(at: passURL, includingPropertiesForKeys: nil)
        print("Copying template files:")
        while let sourceURL = enumerator?.nextObject() as? URL {
            let relativePath = sourceURL.lastPathComponent
            let destinationURL = workingDirURL.appendingPathComponent(relativePath)
            print("- Copying: \(relativePath)")
            
            if !sourceURL.hasDirectoryPath {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                
                if relativePath == "pass.json" {
                    let passJsonData = try Data(contentsOf: destinationURL)
                    var passDict = try JSONSerialization.jsonObject(with: passJsonData, options: [.mutableContainers]) as! [String: Any]
                    
                    print("Verifying pass.json contents:")
                    print("- passTypeIdentifier: \(passDict["passTypeIdentifier"] as? String ?? "missing")")
                    print("- teamIdentifier: \(passDict["teamIdentifier"] as? String ?? "missing")")
                    
                    passDict["passTypeIdentifier"] = passTypeIdentifier
                    passDict["teamIdentifier"] = teamIdentifier
                    passDict["serialNumber"] = card.cardSlug
                    
                    var generic = passDict["generic"] as! [String: Any]
                    var primaryFields = generic["primaryFields"] as! [[String: Any]]
                    var secondaryFields = generic["secondaryFields"] as! [[String: Any]]
                    primaryFields[0]["value"] = "\(card.firstName) \(card.lastName ?? "")"
                    secondaryFields[0]["value"] = card.company ?? ""
                    secondaryFields[1]["value"] = card.jobTitle ?? ""
                    generic["primaryFields"] = primaryFields
                    generic["secondaryFields"] = secondaryFields
                    passDict["generic"] = generic
                    
                    let cardURL = card.getCardURL(username: "")
                    if var barcodes = passDict["barcodes"] as? [[String: Any]], !barcodes.isEmpty {
                        barcodes[0]["message"] = cardURL
                        passDict["barcodes"] = barcodes
                    } else {
                        print("Warning: 'barcodes' key not found or not an array in pass.json")
                        passDict["barcodes"] = [["format": "PKBarcodeFormatQR", "message": cardURL, "messageEncoding": "iso-8859-1"]]
                    }
                    
                    let updatedPassJsonData = try JSONSerialization.data(withJSONObject: passDict, options: [])
                    try updatedPassJsonData.write(to: destinationURL)
                    print("Updated pass.json with passTypeIdentifier: \(passTypeIdentifier), teamIdentifier: \(teamIdentifier)")
                }
            }
        }
        
        var manifest: [String: String] = [:]
        print("\nStarting manifest creation")
        let enumerator2 = FileManager.default.enumerator(at: workingDirURL, includingPropertiesForKeys: nil)
        while let fileURL = enumerator2?.nextObject() as? URL {
            if !fileURL.hasDirectoryPath {
                let relativePath = fileURL.lastPathComponent
                if relativePath != "manifest.json" && relativePath != "signature" {
                    let fileData = try Data(contentsOf: fileURL)
                    print("Hashing file: \(relativePath) (size: \(fileData.count) bytes)")
                    let hash = SHA256.hash(data: fileData)
                    let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
                    manifest[relativePath] = hashString
                }
            }
        }
        
        print("\nManifest contents:")
        manifest.forEach { print("\($0): \($1)") }
        
        let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: [])
        try manifestData.write(to: workingDirURL.appendingPathComponent("manifest.json"))
        print("\nManifest file size: \(manifestData.count) bytes")
        
        print("\nLoading certificate from: \(certificatePath)")
        let certificateData = try Data(contentsOf: URL(fileURLWithPath: certificatePath))
        print("Certificate data loaded, size: \(certificateData.count) bytes")
        
        let certificate = try PKCS12(data: certificateData, password: certificatePassword)
        print("Certificate loaded successfully")
        
        print("\nCreating signature for manifest")
        let signatureData = try certificate.sign(manifestData)
        print("Signature created, size: \(signatureData.count) bytes")
        
        try signatureData.write(to: workingDirURL.appendingPathComponent("signature"))
        
        print("\nCreating final pass package")
        let finalPassURL = try createPassPackage(at: workingDirURL)
        let finalPassData = try Data(contentsOf: finalPassURL)
        print("Final pass package size: \(finalPassData.count) bytes")
        
        print("\nAttempting to create PKPass")
        let pass = try PKPass(data: finalPassData)
        print("PKPass created successfully")
        
        try FileManager.default.removeItem(at: workingDirURL)
        return pass
    }
    
    private func createPassPackage(at workingDirURL: URL) throws -> URL {
        let passURL = workingDirURL.appendingPathComponent("pass.pkpass")
        guard let archive = try? Archive(url: passURL, accessMode: .create) else {
            throw WalletError.passCreationFailed
        }
        
        let enumerator = FileManager.default.enumerator(at: workingDirURL, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if !fileURL.hasDirectoryPath {
                let relativePath = fileURL.lastPathComponent
                try archive.addEntry(with: relativePath, relativeTo: workingDirURL)
            }
        }
        return passURL
    }
}

enum WalletError: Error, LocalizedError {
    case templateNotFound
    case passCreationFailed
    case signatureInvalid
    case userCancelled
    case duplicatePass
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound: return "Pass template not found"
        case .passCreationFailed: return "Failed to add to Wallet"
        case .signatureInvalid: return "Invalid pass signature"
        case .userCancelled: return "User cancelled"
        case .duplicatePass: return "Pass already exists in Wallet"
        }
    }
}

private class PKCS12 {
    let secIdentity: SecIdentity
    var certificates: [SecCertificate]
    
    init(data: Data, password: String) throws {
        print("Initializing PKCS12")
        var items: CFArray?
        let options = [kSecImportExportPassphrase as String: password] as CFDictionary
        let status = SecPKCS12Import(data as CFData, options, &items)
        guard status == errSecSuccess, let dictArray = items as? [[String: Any]], !dictArray.isEmpty else {
            print("PKCS12 import failed with status: \(status)")
            throw WalletError.signatureInvalid
        }
        
        let dict = dictArray[0]
        self.secIdentity = dict[kSecImportItemIdentity as String] as! SecIdentity
        var certs = dict[kSecImportItemCertChain as String] as! [SecCertificate]
        
        if certs.count == 1, let wwdrURL = Bundle.main.url(forResource: "AppleWWDRCAG4", withExtension: "cer"),
           let wwdrData = try? Data(contentsOf: wwdrURL),
           let wwdrCert = SecCertificateCreateWithData(nil, wwdrData as CFData) {
            certs.append(wwdrCert)
        }
        self.certificates = certs
        print("PKCS12 initialized with \(certs.count) certificates")
    }
    
    func sign(_ data: Data) throws -> Data {
        print("Starting signature process")
        
        var privateKey: SecKey?
        let status = SecIdentityCopyPrivateKey(secIdentity, &privateKey)
        guard status == errSecSuccess, let key = privateKey else {
            print("Failed to extract private key with status: \(status)")
            throw WalletError.signatureInvalid
        }
        
        let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256
        guard SecKeyIsAlgorithmSupported(key, .sign, algorithm) else {
            print("Algorithm not supported")
            throw WalletError.signatureInvalid
        }
        
        // Sign the raw manifest data directly
        var error: Unmanaged<CFError>?
        guard let signatureData = SecKeyCreateSignature(key, algorithm, data as CFData, &error) as Data? else {
            print("Signature creation failed: \(error?.takeRetainedValue().localizedDescription ?? "unknown")")
            throw WalletError.signatureInvalid
        }
        
        print("Signature size: \(signatureData.count) bytes")
        print("Signature hex: \(signatureData.map { String(format: "%02x", $0) }.joined())")
        
        // For debugging, log the manifest digest
        let digest = SHA256.hash(data: data)
        let digestData = Data(digest)
        print("Manifest digest: \(digestData.map { String(format: "%02x", $0) }.joined())")
        
        return signatureData
    }
}