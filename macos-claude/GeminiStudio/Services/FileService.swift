import Foundation
import AppKit

@MainActor
class FileService {
    static let shared = FileService()
    
    private let allowedDirectories = [
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!,
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!,
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    ]
    
    private init() {}
    
    static let toolDeclarations_old: [[String: Any]] = [
        [
            "functionDeclarations": [[
                "name": "read_file",
                "description": "Read the contents of a file",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "path": [
                            "type": "string",
                            "description": "The file path to read"
                        ]
                    ],
                    "required": ["path"]
                ]
            ]]
        ],
        [
            "functionDeclarations": [[
                "name": "write_file",
                "description": "Write content to a file",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "path": [
                            "type": "string",
                            "description": "The file path to write to"
                        ],
                        "content": [
                            "type": "string",
                            "description": "The content to write"
                        ]
                    ],
                    "required": ["path", "content"]
                ]
            ]]
        ],
        [
            "functionDeclarations": [[
                "name": "list_directory",
                "description": "List contents of a directory",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "path": [
                            "type": "string",
                            "description": "The directory path to list"
                        ]
                    ],
                    "required": ["path"]
                ]
            ]]
        ],
        [
            "functionDeclarations": [[
                "name": "create_directory",
                "description": "Create a new directory",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "path": [
                            "type": "string",
                            "description": "The directory path to create"
                        ]
                    ],
                    "required": ["path"]
                ]
            ]]
        ]
    ]
    
    func readFile(arguments: [String: Any]) async throws -> String {
        guard let path = arguments["file_path"] as? String else {
            throw ToolError.invalidArguments
        }
        
        // Expand tilde in path if present
        let expandedPath = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        guard isPathAllowed(url) else {
            throw ToolError.fileAccessDenied
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return "File content:\n\(content)"
        } catch {
            throw error
        }
    }
    
    func writeFile(arguments: [String: Any]) async throws -> String {
        Logger.shared.log("📝 writeFile called with arguments: \(arguments)", category: .general)
        Logger.shared.log("📝 Arguments keys: \(arguments.keys.joined(separator: ", "))", category: .general)
        
        // Log each argument individually
        for (key, value) in arguments {
            Logger.shared.log("📝 Argument '\(key)': \(type(of: value)) = \(String(describing: value).prefix(100))", category: .general)
        }
        
        // Check if file operations are enabled first
        if !UserDefaults.standard.bool(forKey: "enableFileOperations") {
            Logger.shared.error("❌ File operations are disabled in settings", category: .general)
            throw ToolError.fileAccessDenied
        }
        
        guard let path = arguments["file_path"] as? String,
              let content = arguments["content"] as? String else {
            Logger.shared.error("❌ Invalid arguments. Expected file_path and content. Got: \(arguments)", category: .general)
            throw ToolError.invalidArguments
        }
        
        // Expand tilde in path if present
        let expandedPath = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        guard isPathAllowed(url) else {
            throw ToolError.fileAccessDenied
        }
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return "File written successfully to: \(path)"
        } catch {
            throw error
        }
    }
    
    func listDirectory(arguments: [String: Any]) async throws -> String {
        guard let path = arguments["path"] as? String else {
            throw ToolError.invalidArguments
        }
        
        // Expand tilde in path if present
        let expandedPath = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        guard isPathAllowed(url) else {
            throw ToolError.fileAccessDenied
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            var result = "Contents of \(path):\n"
            for item in contents {
                let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                let isDirectory = resourceValues.isDirectory ?? false
                let size = resourceValues.fileSize ?? 0
                
                if isDirectory {
                    result += "📁 \(item.lastPathComponent)/\n"
                } else {
                    result += "📄 \(item.lastPathComponent) (\(formatBytes(size)))\n"
                }
            }
            
            return result
        } catch {
            throw error
        }
    }
    
    func createDirectory(arguments: [String: Any]) async throws -> String {
        guard let path = arguments["path"] as? String else {
            throw ToolError.invalidArguments
        }
        
        // Expand tilde in path if present
        let expandedPath = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        guard isPathAllowed(url) else {
            throw ToolError.fileAccessDenied
        }
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return "Directory created successfully at: \(path)"
        } catch {
            throw error
        }
    }
    
    private func isPathAllowed(_ url: URL) -> Bool {
        guard UserDefaults.standard.bool(forKey: "enableFileOperations") else {
            return false
        }
        
        let standardizedURL = url.standardized
        
        for allowedDir in allowedDirectories {
            if standardizedURL.path.hasPrefix(allowedDir.path) {
                return true
            }
        }
        
        return false
    }
    
    private func parseArguments(_ arguments: String?) -> [String: Any]? {
        guard let arguments = arguments,
              let data = arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}