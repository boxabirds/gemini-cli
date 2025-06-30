import Foundation
import Combine
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let geminiService = GeminiService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadConversations()
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        geminiService.$streamingMessage
            .compactMap { $0 }
            .sink { [weak self] content in
                self?.updateStreamingMessage(content)
            }
            .store(in: &cancellables)
        
        geminiService.$toolCalls
            .sink { [weak self] toolCalls in
                self?.updateToolCalls(toolCalls)
            }
            .store(in: &cancellables)
    }
    
    func createNewConversation() -> Conversation {
        let conversation = Conversation(title: "New Conversation")
        conversations.insert(conversation, at: 0)
        currentConversation = conversation
        saveConversations()
        return conversation
    }
    
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            Logger.shared.log("⚠️ Empty message, ignoring", category: .ui)
            return 
        }
        
        Logger.shared.log("💬 Sending message: \(content)", category: .ui)
        
        if currentConversation == nil {
            Logger.shared.log("🆕 Creating new conversation", category: .ui)
            _ = createNewConversation()
        }
        
        let userMessage = Message(
            content: content,
            sender: .user,
            timestamp: Date()
        )
        
        currentConversation?.messages.append(userMessage)
        Logger.shared.log("✅ Added user message to conversation", category: .ui)
        
        // Create assistant message placeholder
        let assistantMessage = Message(
            content: "",
            sender: .assistant,
            timestamp: Date(),
            isStreaming: true
        )
        
        currentConversation?.messages.append(assistantMessage)
        Logger.shared.log("✅ Added assistant placeholder", category: .ui)
        
        Task {
            isLoading = true
            do {
                Logger.shared.log("🚀 Calling geminiService.sendMessage", category: .ui)
                try await geminiService.sendMessage(content, conversation: currentConversation)
                
                // Update conversation title if it's the first message
                if currentConversation?.messages.count == 2 {
                    Logger.shared.log("📝 Updating conversation title", category: .ui)
                    await updateConversationTitle()
                }
            } catch {
                Logger.shared.error("❌ Error sending message: \(error.localizedDescription)", category: .ui)
                self.error = error
                // Remove the assistant placeholder message on error
                if let lastMessage = currentConversation?.messages.last,
                   lastMessage.sender == .assistant && lastMessage.content.isEmpty {
                    currentConversation?.messages.removeLast()
                    Logger.shared.log("🗑 Removed empty assistant message after error", category: .ui)
                }
            }
            isLoading = false
            saveConversations()
        }
    }
    
    private func updateStreamingMessage(_ content: String) {
        guard let currentConversation = currentConversation,
              let lastMessageIndex = currentConversation.messages.indices.last,
              currentConversation.messages[lastMessageIndex].sender == .assistant else {
            Logger.shared.error("⚠️ Cannot update streaming message - no assistant message found", category: .ui)
            return
        }
        
        Logger.shared.log("📝 Updating streaming message: \(content.prefix(50))...", category: .ui)
        
        self.currentConversation?.messages[lastMessageIndex].content = content
        self.currentConversation?.messages[lastMessageIndex].isStreaming = geminiService.isStreaming
        
        if !geminiService.isStreaming {
            Logger.shared.log("✅ Streaming completed, saving conversation", category: .ui)
            saveConversations()
        }
    }
    
    private func updateToolCalls(_ toolCalls: [ToolCall]) {
        guard let currentConversation = currentConversation,
              let lastMessageIndex = currentConversation.messages.indices.last,
              currentConversation.messages[lastMessageIndex].sender == .assistant else {
            return
        }
        
        self.currentConversation?.messages[lastMessageIndex].toolCalls = toolCalls
    }
    
    private func updateConversationTitle() async {
        guard let firstUserMessage = currentConversation?.messages.first(where: { $0.sender == .user }) else {
            return
        }
        
        do {
            let title = try await geminiService.generateTitle(for: firstUserMessage.content)
            currentConversation?.title = title
            saveConversations()
        } catch {
            // Keep default title on error
        }
    }
    
    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        if currentConversation?.id == conversation.id {
            currentConversation = nil
        }
        saveConversations()
    }
    
    func loadConversation(_ conversation: Conversation) {
        currentConversation = conversation
    }
    
    private func loadConversations() {
        // Load from UserDefaults or persistent storage
        if let data = UserDefaults.standard.data(forKey: "conversations"),
           let decoded = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = decoded
        }
    }
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: "conversations")
        }
    }
}

// MARK: - Models

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), title: String, messages: [Message] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var lastMessage: String {
        messages.last?.content.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines) ?? "No messages"
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
    
    var icon: String {
        if messages.isEmpty {
            return "bubble.left"
        } else if messages.count < 5 {
            return "bubble.left.and.bubble.right"
        } else {
            return "text.bubble.fill"
        }
    }
}

struct Message: Identifiable, Codable {
    let id: UUID
    var content: String
    let sender: Sender
    let timestamp: Date
    var isStreaming: Bool = false
    var toolCalls: [ToolCall]?
    var contentType: ContentType = .text
    var codeLanguage: String?
    
    init(id: UUID = UUID(), content: String, sender: Sender, timestamp: Date = Date(), isStreaming: Bool = false, toolCalls: [ToolCall]? = nil, contentType: ContentType = .text, codeLanguage: String? = nil) {
        self.id = id
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.toolCalls = toolCalls
        self.contentType = contentType
        self.codeLanguage = codeLanguage
    }
    
    enum Sender: String, Codable {
        case user
        case assistant
    }
    
    enum ContentType: String, Codable {
        case text
        case code
        case markdown
    }
}

struct ToolCall: Identifiable, Codable {
    let id: String
    let name: String
    var status: Status
    var arguments: [String: Any]
    var result: String?
    var description: String?
    
    enum Status: String, Codable {
        case pending
        case running
        case completed
        case failed
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .running: return "arrow.clockwise"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .running: return .blue
            case .completed: return .green
            case .failed: return .red
            }
        }
    }
    
    // Custom Codable implementation to handle [String: Any]
    enum CodingKeys: String, CodingKey {
        case id, name, status, arguments, result, description
    }
    
    init(id: String = UUID().uuidString, name: String, status: Status, arguments: [String: Any], result: String? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.arguments = arguments
        self.result = result
        self.description = description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decode(Status.self, forKey: .status)
        
        // Decode arguments as JSON string
        if let argsString = try container.decodeIfPresent(String.self, forKey: .arguments),
           let data = argsString.data(using: .utf8),
           let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            arguments = args
        } else {
            arguments = [:]
        }
        
        result = try container.decodeIfPresent(String.self, forKey: .result)
        description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(status, forKey: .status)
        
        // Encode arguments as JSON string
        if let data = try? JSONSerialization.data(withJSONObject: arguments),
           let argsString = String(data: data, encoding: .utf8) {
            try container.encode(argsString, forKey: .arguments)
        }
        
        try container.encodeIfPresent(result, forKey: .result)
        try container.encodeIfPresent(description, forKey: .description)
    }
}