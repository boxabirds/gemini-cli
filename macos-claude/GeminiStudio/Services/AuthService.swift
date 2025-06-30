import Foundation
import Security

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentAuthMethod: AuthMethod?
    
    private let keychainService = "com.gemini.studio"
    private let apiKeyAccount = "gemini-api-key"
    
    enum AuthMethod: String {
        case geminiAPI = "gemini-api"
        case googleOAuth = "google-oauth"
        case vertexAI = "vertex-ai"
    }
    
    init() {
        // First check for environment variable
        if let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty {
            Logger.shared.log("🔑 Found GEMINI_API_KEY in environment: \(String(apiKey.prefix(10)))...", category: .auth)
            GeminiService.shared.configure(apiKey: apiKey)
            isAuthenticated = true
            currentAuthMethod = .geminiAPI
        } else {
            Logger.shared.log("⚠️ No GEMINI_API_KEY in environment, checking stored credentials", category: .auth)
            checkStoredCredentials()
        }
    }
    
    func authenticate(method: AuthMethod, apiKey: String? = nil) {
        switch method {
        case .geminiAPI:
            if let apiKey = apiKey, !apiKey.isEmpty {
                storeAPIKey(apiKey)
                GeminiService.shared.configure(apiKey: apiKey)
                isAuthenticated = true
                currentAuthMethod = method
            }
        case .googleOAuth:
            // Implement OAuth flow
            performGoogleOAuth()
        case .vertexAI:
            // Implement Vertex AI authentication
            performVertexAIAuth()
        }
    }
    
    func signOut() {
        deleteStoredCredentials()
        isAuthenticated = false
        currentAuthMethod = nil
    }
    
    func hasStoredCredentials() -> Bool {
        if let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty {
            return true
        }
        return retrieveAPIKey() != nil
    }
    
    func attemptAutoLogin() {
        // Check environment variable first
        if let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty {
            GeminiService.shared.configure(apiKey: apiKey)
            isAuthenticated = true
            currentAuthMethod = .geminiAPI
        } else if let apiKey = retrieveAPIKey() {
            GeminiService.shared.configure(apiKey: apiKey)
            isAuthenticated = true
            currentAuthMethod = .geminiAPI
        }
    }
    
    private func checkStoredCredentials() {
        if let apiKey = retrieveAPIKey() {
            GeminiService.shared.configure(apiKey: apiKey)
            isAuthenticated = true
            currentAuthMethod = .geminiAPI
        }
    }
    
    // MARK: - Keychain Operations
    
    private func storeAPIKey(_ apiKey: String) {
        let data = apiKey.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error storing API key: \(status)")
        }
    }
    
    private func retrieveAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let apiKey = String(data: data, encoding: .utf8) {
            return apiKey
        }
        
        return nil
    }
    
    private func deleteStoredCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - OAuth Implementation
    
    private func performGoogleOAuth() {
        // This would implement the OAuth flow
        // For now, we'll simulate it
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isAuthenticated = true
            self?.currentAuthMethod = .googleOAuth
        }
    }
    
    private func performVertexAIAuth() {
        // This would implement Vertex AI authentication
        // For now, we'll simulate it
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isAuthenticated = true
            self?.currentAuthMethod = .vertexAI
        }
    }
}