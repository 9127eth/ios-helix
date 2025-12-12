//
//  OpenAIService.swift
//  Helix
//
//  Created by Richard Waithe on 12/8/24.
//

import Foundation

enum OpenAIError: Error {
    case invalidResponse
    case apiError(String)
    case decodingError
    case rateLimitExceeded
}

struct OpenAIResponse: Codable {
    let name: String
    let position: String
    let company: String
    let phone: String
    let email: String
    let address: String
    let website: String
}

class RateLimiter {
    private let queue = DispatchQueue(label: "com.helix.ratelimiter")
    private var lastRequestTime: Date?
    private let minInterval: TimeInterval // Minimum time between requests in seconds
    private let maxRequestsPerMinute: Int
    private var requestCount = 0
    private var minuteStartTime: Date?
    
    init(minInterval: TimeInterval = 1.0, maxRequestsPerMinute: Int = 20) {
        self.minInterval = minInterval
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }
    
    func shouldAllowRequest() async -> Bool {
        await queue.sync {
            let now = Date()
            
            // Initialize or reset minute window
            if minuteStartTime == nil || now.timeIntervalSince(minuteStartTime!) >= 60 {
                minuteStartTime = now
                requestCount = 0
            }
            
            // Check rate limits
            if let lastRequest = lastRequestTime,
               now.timeIntervalSince(lastRequest) < minInterval {
                return false
            }
            
            if requestCount >= maxRequestsPerMinute {
                return false
            }
            
            // Update tracking
            lastRequestTime = now
            requestCount += 1
            return true
        }
    }
}

class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let rateLimiter: RateLimiter
    
    init() {
        // Read from Info.plist instead of ProcessInfo
        guard let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String else {
            fatalError("OPENAI_API_KEY not found in Info.plist")
        }
        self.apiKey = apiKey
        self.rateLimiter = RateLimiter()
        
        #if DEBUG
        print("OpenAI API Key present: \(!self.apiKey.isEmpty)")
        #endif
    }
    
    func processBusinessCard(text: String) async throws -> OpenAIResponse {
        // Check rate limit before proceeding
        guard await rateLimiter.shouldAllowRequest() else {
            throw OpenAIError.rateLimitExceeded
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
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are a precise business card information extractor."],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.3
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            // Log the error response for debugging
            let errorResponse = String(data: data, encoding: .utf8) ?? "No response body"
            print("OpenAI API Error Response: ", errorResponse)
            print("OpenAI API Status Code: ", httpResponse.statusCode)
            throw OpenAIError.apiError(errorResponse)
        }
        
        // Print raw response for debugging
        print("OpenAI Raw Response:", String(data: data, encoding: .utf8) ?? "")
        
        // Parse the response
        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = jsonResponse["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            // Remove any markdown formatting if present
            let cleanContent = content.replacingOccurrences(of: "```json\n", with: "")
                .replacingOccurrences(of: "\n```", with: "")
            
            guard let jsonData = cleanContent.data(using: .utf8) else {
                throw OpenAIError.decodingError
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(OpenAIResponse.self, from: jsonData)
        }
        
        throw OpenAIError.decodingError
    }
}

