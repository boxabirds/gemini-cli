import Foundation
import AppKit

@MainActor
class ToolExecutor {
    static let shared = ToolExecutor()
    
    private init() {}
    
    func execute(_ toolCall: ToolCall) async throws -> String {
        Logger.shared.log("🔧 Executing tool: \(toolCall.name) with arguments: \(toolCall.arguments)", category: .general)
        
        switch toolCall.name {
        case "read_file":
            return try await FileService.shared.readFile(arguments: toolCall.arguments)
        case "write_file":
            return try await FileService.shared.writeFile(arguments: toolCall.arguments)
        case "list_directory":
            return try await FileService.shared.listDirectory(arguments: toolCall.arguments)
        case "create_directory":
            return try await FileService.shared.createDirectory(arguments: toolCall.arguments)
        case "web_search":
            return try await performWebSearch(arguments: toolCall.arguments)
        case "run_command":
            return try await runCommand(arguments: toolCall.arguments)
        default:
            throw ToolError.unknownTool(toolCall.name)
        }
    }
    
    private func performWebSearch(arguments: [String: Any]) async throws -> String {
        guard let query = arguments["query"] as? String else {
            throw ToolError.invalidArguments
        }
        
        // Simulate web search
        return "Search results for '\(query)':\n1. Example result 1\n2. Example result 2\n3. Example result 3"
    }
    
    private func runCommand(arguments: [String: Any]) async throws -> String {
        guard let command = arguments["command"] as? String else {
            throw ToolError.invalidArguments
        }
        
        // Safety check
        let dangerousCommands = ["rm", "delete", "format", "sudo"]
        if dangerousCommands.contains(where: command.lowercased().contains) {
            throw ToolError.dangerousCommand
        }
        
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        try task.run()
        task.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        var result = ""
        if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
            result += "Output:\n\(output)"
        }
        if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
            result += "\nError:\n\(error)"
        }
        
        return result.isEmpty ? "Command executed successfully with no output." : result
    }
    
}

enum ToolError: LocalizedError {
    case userRejected
    case unknownTool(String)
    case invalidArguments
    case dangerousCommand
    case fileAccessDenied
    
    var errorDescription: String? {
        switch self {
        case .userRejected:
            return "User rejected the tool execution"
        case .unknownTool(let name):
            return "Unknown tool: \(name)"
        case .invalidArguments:
            return "Invalid tool arguments"
        case .dangerousCommand:
            return "This command is potentially dangerous and has been blocked"
        case .fileAccessDenied:
            return "File access denied"
        }
    }
}