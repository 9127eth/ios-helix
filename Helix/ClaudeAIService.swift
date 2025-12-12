import Foundation

enum ClaudeError: Error {
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
        guard let apiKey = Bundle.main.infoDictionary?["CLAUDE_API_KEY"] as? String else {
            fatalError("CLAUDE_API_KEY not found in Info.plist")
        }
        self.apiKey = apiKey
        self.rateLimiter = RateLimiter()
        
        // Debug print to verify API key
        #if DEBUG
        print("Claude API Key present: \(!self.apiKey.isEmpty)")
        #endif
    }
    
    func processBusinessCard(text: String) async throws -> OpenAIResponse {
        // Check rate limit before proceeding
        guard await rateLimiter.shouldAllowRequest() else {
            throw ClaudeError.rateLimitExceeded
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
        
        Return only a JSON object with these fields:
        {
          "name": "Full Name",
          "position": "Job Title",
          "company": "Company Name",
          "phone": "Phone Number",
          "email": "Email Address",
          "address": "Full Address",
          "website": "Website URL"
        }
        """
        
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            // Log the error response
            let errorResponse = String(data: data, encoding: .utf8) ?? "No response body"
            print("Claude API Error Response: ", errorResponse)
            
            switch httpResponse.statusCode {
            case 401:
                throw ClaudeError.apiError("Authentication failed: Invalid API key")
            case 400:
                throw ClaudeError.apiError("Bad request: \(errorResponse)")
            case 429:
                throw ClaudeError.rateLimitExceeded
            default:
                throw ClaudeError.apiError("API request failed with status \(httpResponse.statusCode): \(errorResponse)")
            }
        }
        
        // Print raw response for debugging
        print("Claude Raw Response:", String(data: data, encoding: .utf8) ?? "")
        
        // Parse the response
        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let content = jsonResponse["content"] as? [[String: Any]],
           let firstContent = content.first,
           let text = firstContent["text"] as? String {
            
            // Remove any markdown formatting if present
            let cleanContent = text.replacingOccurrences(of: "```json\n", with: "")
                .replacingOccurrences(of: "\n```", with: "")
            
            guard let jsonData = cleanContent.data(using: .utf8) else {
                throw ClaudeError.decodingError
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(OpenAIResponse.self, from: jsonData)
        }
        
        throw ClaudeError.decodingError
    }
}
