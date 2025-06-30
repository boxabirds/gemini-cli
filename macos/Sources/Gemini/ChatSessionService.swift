import Foundation

class ChatSessionService {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    init() {
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func saveChat(messages: [Message], completion: @escaping (Result<Void, Error>) -> Void) {
        let chatSession = messages.map { "\($0.isUser ? "User" : "Gemini"): \($0.text)" }.joined(separator: "\n")
        let fileName = "chat-\(Date().timeIntervalSince1970).txt"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            try chatSession.write(to: fileURL, atomically: true, encoding: .utf8)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func loadSavedChats() -> [URL] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.pathExtension == "txt" }
        } catch {
            print("Error loading saved chats: \(error)")
            return []
        }
    }
}
