//
//  ClaudeAIService.swift
//  Helix
//
//  Created by Richard Waithe on 12/13/24.
//

import Foundation

enum ClaudeAIError: Error {
    case invalidResponse
    case apiError(String)
    case decodingError
    case rateLimitExceeded
}

class ClaudeAIService {
    private let apiKey: String
    private let endpoint = "https://api.anthropic.com/v1/messages"
    private let rateLimiter: RateLimiter
    
    init() {
        self.apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
        self.rateLimiter = RateLimiter()
    }
    
    func processBusinessCard(text: String) async throws -> OpenAIResponse {
        // Check rate limit before proceeding
        guard await rateLimiter.shouldAllowRequest() else {
            throw ClaudeAIError.rateLimitExceeded
        }
        
        let prompt = """
        You are an AI designed to extract and organize information from text. The text will be either a business card or a tradeshow badge. Extract key details from this business card text and present them in a structured format. Also some general rules:
         - do not include prefixes like "Mr.", "Ms.", "Dr.", etc. Names should just start with the first name. You can include suffixes like "Jr.", "Sr.", "III", pharmd, md, bsn, rn, md, etc. 
         - if multiple phone numbers are found, prioritize cell/mobile numbers. Then office numbers if no cell. Defininitely dont want fax numbers. But only extract one phone number.
         - if a website is not present, but an email address is, we can assume the domain from the email address is the website.
         - do not include registerd trademark symbols.
         - phone numbers should be in the format of (123) 456-7890
         - Ensure that all caps text is converted to proper upper and lower case formatting for a clean appearance, while preserving accurate capitalization for company names and personal names. However, do not alter someone's credentials e.g. PharmD, MD, BSN, RN, CPhT, etc.

        \(text)
        """
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "claude-3-sonnet-20240229",
            "messages": messages,
            "max_tokens": 1024,
            "temperature": 0.3
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("anthropic/claude-3", forHTTPHeaderField: "x-api-vendor")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ClaudeAIError.invalidResponse
        }
        
        // Print raw response for debugging
        print("Claude Raw Response:", String(data: data, encoding: .utf8) ?? "")
        
        // Parse the response
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResponse["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw ClaudeAIError.decodingError
        }
            
        // Extract JSON from the response text
        let jsonStartIndex = text.firstIndex(of: "{") ?? text.startIndex
        let jsonEndIndex = text.lastIndex(of: "}") ?? text.endIndex
        let jsonString = String(text[jsonStartIndex...jsonEndIndex])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ClaudeAIError.decodingError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(OpenAIResponse.self, from: jsonData)
    }
}

