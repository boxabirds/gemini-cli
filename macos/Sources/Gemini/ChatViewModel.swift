import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published private(set) var savedChats: [URL] = []
    @Published private(set) var files: [String] = []

    let geminiService = GeminiService()
    let fileSystemService = FileSystemService()
    private let chatSessionService = ChatSessionService()

    init() {
        geminiService.setApiKey(UserDefaults.standard.string(forKey: "apiKey") ?? "")
        loadSavedChats()
        loadFiles(at: FileManager.default.homeDirectoryForCurrentUser.path)
    }

    func sendMessage(text: String) {
        messages.append(Message(text: text, isUser: true))

        Task {
            do {
                let responseText = try await geminiService.sendMessage(text: text, history: messages)
                messages.append(Message(text: responseText, isUser: false))
            } catch {
                messages.append(Message(text: "Error: \(error.localizedDescription)", isUser: false))
            }
        }
    }

    func clearChat() {
        messages.removeAll()
    }

    func newChat() {
        clearChat()
    }

    func saveChat() {
        chatSessionService.saveChat(messages: messages) { result in
            switch result {
            case .success:
                self.loadSavedChats()
            case .failure(let error):
                print("Error saving chat: \(error)")
            }
        }
    }

    func loadSavedChats() {
        savedChats = chatSessionService.loadSavedChats()
    }

    func loadFiles(at path: String) {
        files = fileSystemService.listFiles(at: path)
    }
}
