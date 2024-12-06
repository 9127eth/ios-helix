import Foundation

enum AppEnvironment {
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Info.plist not found")
        }
        return dict
    }()
    
    static let apiBaseURL: String = {
        guard let baseURL = infoDictionary["API_BASE_URL"] as? String else {
            fatalError("API_BASE_URL not found in environment")
        }
        return baseURL
    }()
    
    static let apiKey: String = {
        guard let key = infoDictionary["API_KEY"] as? String else {
            fatalError("API_KEY not found in environment")
        }
        return key
    }()
} 