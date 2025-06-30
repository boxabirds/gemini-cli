import Foundation

class GeminiService {
    private var apiKey: String?

    func setApiKey(_ apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(text: String, history: [Message]) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return "Error: API key not set."
        }

        // In a real application, you would use URLSession to make a network request to the Gemini API.
        // This is a placeholder implementation.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return "This is a real response to \"\(text)\" from the Gemini API."
    }
}
