import UIKit

struct ScannedContactData {
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var company: String = ""
    var position: String = ""
    var website: String = ""
    var address: String = ""
    var confidenceScores: [String: Float] = [:]
    var capturedImage: UIImage?
    
    var isEmpty: Bool {
        name.isEmpty && email.isEmpty && phone.isEmpty && 
        company.isEmpty && position.isEmpty && website.isEmpty && 
        address.isEmpty
    }
    
    var lowConfidenceFields: [String] {
        confidenceScores.filter { $0.value < 0.7 }.map { $0.key }
    }
}

class TextProcessor {
    private let commonTitles = Set(["mr", "mrs", "ms", "dr", "prof", "ceo", "cto", "cfo", "vp", "director"])
    private let companyIdentifiers = Set(["inc", "corp", "llc", "ltd", "company", "co", "corporation", "incorporated"])
    
    func processText(_ text: String) -> (data: ScannedContactData, confidence: [String: Float]) {
        var data = ScannedContactData()
        var confidence: [String: Float] = [:]
        
        // Split text into lines for better processing
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Process each line
        for (index, line) in lines.enumerated() {
            // Email has highest priority as it's most distinctive
            if data.email.isEmpty, let email = extractEmail(from: line) {
                data.email = email.text
                confidence["email"] = email.confidence
                continue
            }
            
            // Phone number detection
            if data.phone.isEmpty, let phone = extractPhone(from: line) {
                data.phone = phone.text
                confidence["phone"] = phone.confidence
                continue
            }
            
            // Website detection
            if data.website.isEmpty, let website = extractWebsite(from: line) {
                data.website = website.text
                confidence["website"] = website.confidence
                continue
            }
            
            // Name detection (usually in first few lines)
            if data.name.isEmpty && index < 3 {
                if let name = extractName(from: line) {
                    data.name = name.text
                    confidence["name"] = name.confidence
                    continue
                }
            }
            
            // Position detection
            if data.position.isEmpty, let position = extractPosition(from: line) {
                data.position = position.text
                confidence["position"] = position.confidence
                continue
            }
            
            // Company detection
            if data.company.isEmpty, let company = extractCompany(from: line) {
                data.company = company.text
                confidence["company"] = company.confidence
                continue
            }
        }
        
        // Address is usually multi-line, so process the whole text
        if data.address.isEmpty, let address = extractAddress(from: text) {
            data.address = address.text
            confidence["address"] = address.confidence
        }
        
        data.confidenceScores = confidence
        return (data, confidence)
    }
    
    private func extractEmail(from text: String) -> (text: String, confidence: Float)? {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        if let match = text.range(of: emailRegex, options: .regularExpression) {
            let email = String(text[match])
            // Higher confidence if it's a business email
            let confidence: Float = email.contains(".com") ? 0.95 : 0.9
            return (email, confidence)
        }
        return nil
    }
    
    private func extractPhone(from text: String) -> (text: String, confidence: Float)? {
        let phonePatterns = [
            "\\b\\+?1?[-.]?\\s*\\(?\\d{3}\\)?[-.]?\\s*\\d{3}[-.]?\\s*\\d{4}\\b",  // Various US formats
            "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b",  // Basic format
            "\\b\\(\\d{3}\\)\\s*\\d{3}[-.]?\\d{4}\\b"  // (123) 456-7890
        ]
        
        for pattern in phonePatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let phone = String(text[match])
                    .replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                
                // Higher confidence for certain indicators
                let lowerText = text.lowercased()
                let confidence: Float = lowerText.contains("cell") || lowerText.contains("mobile") ? 0.95 :
                                     lowerText.contains("phone") ? 0.9 : 0.85
                return (phone, confidence)
            }
        }
        return nil
    }
    
    private func extractWebsite(from text: String) -> (text: String, confidence: Float)? {
        let urlRegex = "(?i)\\b(?:https?://)?(?:www\\.)?[a-z0-9-]+(?:\\.[a-z]{2,})+(?:/[^\\s]*)?\\b"
        if let match = text.range(of: urlRegex, options: .regularExpression) {
            let website = String(text[match])
            // Higher confidence if it has http/https
            let confidence: Float = website.lowercased().hasPrefix("http") ? 0.95 : 0.85
            return (website, confidence)
        }
        return nil
    }
    
    private func extractName(from text: String) -> (text: String, confidence: Float)? {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let lowerText = text.lowercased()
        
        // Skip if line contains common non-name indicators
        if lowerText.contains("@") || lowerText.contains("www.") || 
           lowerText.contains(".com") || lowerText.contains("tel:") {
            return nil
        }
        
        // Check for common titles
        let hasTitle = commonTitles.contains { lowerText.contains($0) }
        
        // Name should be 2-4 words
        if words.count >= 2 && words.count <= 4 {
            // Higher confidence if it contains a title or is in first 2 lines
            let confidence: Float = hasTitle ? 0.9 : 0.75
            return (text, confidence)
        }
        return nil
    }
    
    private func extractPosition(from text: String) -> (text: String, confidence: Float)? {
        let positionTitles = ["manager", "director", "president", "engineer", "developer",
                             "specialist", "coordinator", "analyst", "consultant",
                             "supervisor", "lead", "head", "chief"]
        
        let lowerText = text.lowercased()
        
        // Check for common titles
        if positionTitles.contains(where: { lowerText.contains($0) }) ||
           commonTitles.contains(where: { lowerText.contains($0) }) {
            // Skip if it's clearly part of a company name
            if companyIdentifiers.contains(where: { lowerText.contains($0) }) {
                return nil
            }
            return (text, 0.85)
        }
        return nil
    }
    
    private func extractCompany(from text: String) -> (text: String, confidence: Float)? {
        let lowerText = text.lowercased()
        
        // Skip if line contains common non-company indicators
        if lowerText.contains("@") || lowerText.contains("tel:") {
            return nil
        }
        
        // Check for company identifiers
        if companyIdentifiers.contains(where: { lowerText.contains($0) }) {
            return (text, 0.9)
        }
        
        // If line contains "at" or "@" between words, take the part after
        if let range = text.range(of: "\\bat\\s+[A-Z]", options: .regularExpression) {
            let companyName = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            return (companyName, 0.8)
        }
        
        return nil
    }
    
    private func extractAddress(from text: String) -> (text: String, confidence: Float)? {
        let addressIndicators = ["street", "st", "avenue", "ave", "road", "rd", "boulevard", "blvd",
                               "lane", "ln", "drive", "dr", "circle", "court", "ct", "suite",
                               "floor", "fl", "apt", "unit"]
        
        // Look for lines containing postal codes
        let postalRegex = "\\b\\d{5}(?:-\\d{4})?\\b" // US ZIP code format
        
        let lines = text.components(separatedBy: .newlines)
        var addressLines: [String] = []
        var foundAddress = false
        
        for (index, line) in lines.enumerated() {
            let lowerLine = line.lowercased()
            
            // Check for address indicators
            if addressIndicators.contains(where: { lowerLine.contains($0) }) ||
               line.range(of: postalRegex, options: .regularExpression) != nil {
                foundAddress = true
                // Include previous line if it exists (might contain street number)
                if index > 0 {
                    addressLines.append(lines[index - 1])
                }
                addressLines.append(line)
                // Include next line if it exists (might contain city/state)
                if index < lines.count - 1 {
                    addressLines.append(lines[index + 1])
                }
                break
            }
        }
        
        if foundAddress {
            return (addressLines.joined(separator: "\n"), 0.8)
        }
        
        return nil
    }
} 