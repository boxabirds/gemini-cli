import Foundation
import Combine

@MainActor
class GeminiService: ObservableObject {
    static let shared = GeminiService()
    
    @Published var isStreaming = false
    @Published var streamingMessage: String?
    @Published var toolCalls: [ToolCall] = []
    
    private var apiKey: String?
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private var currentTask: Task<Void, Error>?
    
    private init() {}
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    private var currentConversation: Conversation?
    
    func sendMessage(_ content: String, conversation: Conversation? = nil) async throws {
        Logger.shared.log("📤 Sending message: \(content)", category: .api)
        
        guard let apiKey = apiKey else {
            Logger.shared.error("❌ No API key configured", category: .api)
            throw GeminiError.notAuthenticated
        }
        
        Logger.shared.log("🔑 API key present: \(String(apiKey.prefix(10)))...", category: .api)
        
        isStreaming = true
        streamingMessage = ""
        toolCalls = []
        currentConversation = conversation
        
        let request = try createRequest(content: content, conversation: conversation)
        Logger.shared.log("📋 Request created for model: \(UserDefaults.standard.string(forKey: "selectedModel") ?? "default")", category: .api)
        
        currentTask = Task {
            do {
                Logger.shared.log("🌐 Starting URLSession request...", category: .api)
                let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    Logger.shared.error("❌ Invalid response type", category: .api)
                    throw GeminiError.invalidResponse
                }
                
                Logger.shared.log("📥 Response status code: \(httpResponse.statusCode)", category: .api)
                
                guard httpResponse.statusCode == 200 else {
                    Logger.shared.error("❌ Non-200 status code: \(httpResponse.statusCode)", category: .api)
                    throw GeminiError.invalidResponse
                }
                
                var buffer = ""
                var chunkCount = 0
                
                Logger.shared.log("🔄 Starting to read stream bytes...", category: .api)
                
                for try await line in asyncBytes.lines {
                    Logger.shared.log("📄 Received line: \(String(line.prefix(100)))...", category: .api)
                    
                    if line.hasPrefix("data: ") {
                        chunkCount += 1
                        let jsonString = String(line.dropFirst(6))
                        
                        // Skip empty data or [DONE] message
                        if jsonString == "[DONE]" || jsonString.isEmpty {
                            continue
                        }
                        
                        Logger.shared.log("📦 Processing chunk #\(chunkCount): \(String(jsonString.prefix(100)))...", category: .api)
                        await processStreamChunk(jsonString)
                    }
                }
                
                Logger.shared.log("✅ Stream completed. Total chunks: \(chunkCount)", category: .api)
                isStreaming = false
            } catch {
                Logger.shared.error("❌ Stream error: \(error.localizedDescription)", category: .api)
                isStreaming = false
                throw error
            }
        }
        
        try await currentTask?.value
    }
    
    func cancelCurrentRequest() {
        currentTask?.cancel()
        isStreaming = false
    }
    
    private func createRequest(content: String, conversation: Conversation? = nil) throws -> URLRequest {
        guard let apiKey = apiKey else {
            Logger.shared.error("❌ No API key in createRequest", category: .api)
            throw GeminiError.notAuthenticated
        }
        
        let model = UserDefaults.standard.string(forKey: "selectedModel") ?? "gemini-2.5-flash"
        let urlString = "\(baseURL)/models/\(model):streamGenerateContent?alt=sse"
        Logger.shared.log("🔗 Request URL: \(urlString)", category: .api)
        
        guard var components = URLComponents(string: urlString) else {
            throw GeminiError.invalidResponse
        }
        
        // Add API key as query parameter (not in URL for security)
        components.queryItems = (components.queryItems ?? []) + [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "alt", value: "sse")
        ]
        
        guard let url = components.url else {
            throw GeminiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let temperature = UserDefaults.standard.double(forKey: "temperature")
        let maxTokens = Int(UserDefaults.standard.double(forKey: "maxTokens"))
        let topP = UserDefaults.standard.double(forKey: "topP")
        
        // Build conversation history
        var contents: [[String: Any]] = []
        
        // Add previous messages from conversation
        if let conversation = conversation {
            for message in conversation.messages {
                // Skip the current streaming message
                if message.isStreaming { continue }
                
                var parts: [[String: Any]] = []
                
                // Add text content
                if !message.content.isEmpty {
                    parts.append(["text": message.content])
                }
                
                // Add tool calls as function responses
                if let toolCalls = message.toolCalls {
                    for toolCall in toolCalls {
                        if toolCall.status == .completed, let result = toolCall.result {
                            parts.append([
                                "functionResponse": [
                                    "name": toolCall.name,
                                    "response": ["output": result]
                                ]
                            ])
                        }
                    }
                }
                
                if !parts.isEmpty {
                    contents.append([
                        "parts": parts,
                        "role": message.sender == .user ? "user" : "model"
                    ])
                }
            }
        }
        
        // Add current message
        contents.append([
            "parts": [["text": content]],
            "role": "user"
        ])
        
        // Build request body exactly like @google/genai
        var requestBody: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": temperature == 0 ? 0.7 : temperature,
                "maxOutputTokens": maxTokens == 0 ? 4096 : maxTokens,
                "topP": topP == 0 ? 0.9 : topP
            ]
        ]
        
        // Add tools at root level, not in generationConfig
        let tools = getToolDeclarations()
        Logger.shared.log("🔧 Tools array: \(tools)", category: .api)
        if !tools.isEmpty {
            requestBody["tools"] = tools
            Logger.shared.log("✅ Added \(tools.count) tool declarations to request", category: .api)
        } else {
            Logger.shared.log("⚠️ No tools to add to request", category: .api)
        }
        
        Logger.shared.log("📝 Request body: \(requestBody)", category: .api)
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        Logger.shared.log("📦 Request body size: \(request.httpBody?.count ?? 0) bytes", category: .api)
        
        return request
    }
    
    private func getToolDescription(name: String, args: [String: Any]) -> String? {
        switch name {
        case "write_file":
            if let filePath = args["file_path"] as? String {
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                return "✏️ Writing to \(fileName)"
            }
        case "read_file":
            if let filePath = args["file_path"] as? String {
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                return "📖 Reading \(fileName)"
            }
        case "list_directory":
            if let path = args["path"] as? String {
                return "📁 Listing directory: \(path)"
            }
        default:
            return "🔧 Executing \(name)"
        }
        return nil
    }
    
    private func processStreamChunk(_ jsonString: String) async {
        guard let data = jsonString.data(using: .utf8) else {
            Logger.shared.error("❌ Failed to convert JSON string to data", category: .api)
            return
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Logger.shared.error("❌ Failed to parse JSON: \(jsonString)", category: .api)
            return
        }
        
        Logger.shared.log("🔍 Parsed JSON: \(json)", category: .api)
        
        // Extract text content
        if let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]] {
            
            for part in parts {
                if let text = part["text"] as? String {
                    streamingMessage = (streamingMessage ?? "") + text
                    Logger.shared.log("📝 Text chunk: \(text)", category: .api)
                }
                
                // Handle tool calls (function calls)
                if let functionCall = part["functionCall"] as? [String: Any],
                   let name = functionCall["name"] as? String,
                   let args = functionCall["args"] as? [String: Any] {
                    Logger.shared.log("🔧 Tool call detected: \(name)", category: .api)
                    Logger.shared.log("📋 Tool arguments: \(args)", category: .api)
                    
                    let description = getToolDescription(name: name, args: args)
                    let toolCall = ToolCall(
                        name: name,
                        status: .pending,
                        arguments: args,
                        description: description
                    )
                    toolCalls.append(toolCall)
                    
                    // Don't execute immediately - just mark as pending
                    // The CLI shows the tool call in the UI first
                    Logger.shared.log("⏸️ Tool call detected: \(name)", category: .api)
                    
                    // Check if we should auto-execute
                    Task { @MainActor in
                        if !UserDefaults.standard.bool(forKey: "requireToolConfirmation") {
                            // Auto-execute after a brief delay to show the UI
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            await self.executeToolCall(toolCall)
                        }
                    }
                }
            }
        }
    }
    
    func executeToolCall(_ toolCall: ToolCall) async {
        Logger.shared.log("🚀 Starting execution of tool: \(toolCall.name)", category: .api)
        
        // Update status
        if let index = toolCalls.firstIndex(where: { $0.id == toolCall.id }) {
            toolCalls[index].status = .running
        }
        
        do {
            let result = try await ToolExecutor.shared.execute(toolCall)
            Logger.shared.log("✅ Tool execution succeeded: \(result)", category: .api)
            
            // Update with result
            if let index = toolCalls.firstIndex(where: { $0.id == toolCall.id }) {
                toolCalls[index].status = .completed
                toolCalls[index].result = result
            }
            
            // Send tool response back to API
            try await sendToolResponse(toolCall: toolCall, result: result)
            
        } catch {
            Logger.shared.error("❌ Tool execution failed: \(error.localizedDescription)", category: .api)
            if let index = toolCalls.firstIndex(where: { $0.id == toolCall.id }) {
                toolCalls[index].status = .failed
                toolCalls[index].result = error.localizedDescription
            }
        }
    }
    
    private func sendToolResponse(toolCall: ToolCall, result: String) async throws {
        // The CLI automatically continues the conversation with tool results
        Logger.shared.log("✅ Tool response recorded: \(result)", category: .api)
        
        // Check if all tool calls for this message are completed
        let allCompleted = toolCalls.allSatisfy { $0.status == .completed || $0.status == .failed }
        
        if allCompleted && !UserDefaults.standard.bool(forKey: "requireToolConfirmation") {
            Logger.shared.log("🔄 All tools completed, continuing conversation", category: .api)
            
            // Continue the conversation with tool results
            // The next API call will include the function responses in the conversation history
            // For now, we need to send an empty message to trigger the continuation
            try await continueWithToolResults()
        }
    }
    
    private func continueWithToolResults() async throws {
        // Send an empty user message to continue the conversation
        // The tool results will be included in the conversation history
        isStreaming = true
        streamingMessage = ""
        
        let request = try createRequest(content: "", conversation: currentConversation)
        
        currentTask = Task {
            do {
                let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw GeminiError.invalidResponse
                }
                
                for try await line in asyncBytes.lines {
                    if line.hasPrefix("data: ") {
                        let jsonString = String(line.dropFirst(6))
                        if jsonString != "[DONE]" && !jsonString.isEmpty {
                            await processStreamChunk(jsonString)
                        }
                    }
                }
                
                isStreaming = false
            } catch {
                Logger.shared.error("❌ Continuation error: \(error.localizedDescription)", category: .api)
                isStreaming = false
                throw error
            }
        }
        
        try await currentTask?.value
    }
    
    func generateTitle(for content: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw GeminiError.notAuthenticated
        }
        
        let prompt = "Generate a short, concise title (max 5 words) for a conversation that starts with: '\(content.prefix(100))'. Return only the title, no quotes or additional text."
        
        let model = "gemini-2.5-flash" // Use fast model for title generation
        let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.5,
                "maxOutputTokens": 20
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GenerateContentResponse.self, from: data)
        
        if let text = response.candidates?.first?.content?.parts?.first?.text {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "New Conversation"
    }
    
    private func getToolDeclarations() -> [[String: Any]] {
        // Build tool declarations based on settings
        var functionDeclarations: [[String: Any]] = []
        
        // Default to true if not set
        if UserDefaults.standard.object(forKey: "enableFileOperations") == nil || UserDefaults.standard.bool(forKey: "enableFileOperations") {
            functionDeclarations.append(contentsOf: [
            [
                "name": "write_file",
                "description": "Write content to a file. Creates the file if it doesn't exist, or overwrites if it does.",
                "parameters": [
                    "type": "OBJECT",
                    "properties": [
                        "file_path": [
                            "type": "STRING",
                            "description": "The absolute path to the file to write"
                        ],
                        "content": [
                            "type": "STRING",
                            "description": "The content to write to the file"
                        ]
                    ],
                    "required": ["file_path", "content"]
                ]
            ],
            [
                "name": "read_file",
                "description": "Read the contents of a file",
                "parameters": [
                    "type": "OBJECT",
                    "properties": [
                        "file_path": [
                            "type": "STRING",
                            "description": "The absolute path to the file to read"
                        ]
                    ],
                    "required": ["file_path"]
                ]
            ],
            [
                "name": "list_directory",
                "description": "List contents of a directory",
                "parameters": [
                    "type": "OBJECT",
                    "properties": [
                        "path": [
                            "type": "STRING",
                            "description": "The directory path to list"
                        ]
                    ],
                    "required": ["path"]
                ]
            ]
            ])
        }
        
        if UserDefaults.standard.bool(forKey: "enableWebSearch") {
            functionDeclarations.append([
                "name": "web_search",
                "description": "Search the web for information",
                "parameters": [
                    "type": "OBJECT",
                    "properties": [
                        "query": [
                            "type": "STRING",
                            "description": "The search query"
                        ]
                    ],
                    "required": ["query"]
                ]
            ])
        }
        
        // Return in the format expected by Gemini API
        // The CLI shows tools as an array with one object containing functionDeclarations
        if functionDeclarations.isEmpty {
            return []
        }
        return [["functionDeclarations": functionDeclarations]]
    }
}

// MARK: - Response Models

private struct GenerateContentResponse: Codable {
    let candidates: [Candidate]?
    
    struct Candidate: Codable {
        let content: Content?
        
        struct Content: Codable {
            let parts: [Part]?
            
            struct Part: Codable {
                let text: String?
            }
        }
    }
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please provide an API key."
        case .invalidResponse:
            return "Invalid response from server."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}