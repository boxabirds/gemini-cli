import SwiftUI
import AppKit

enum ToolConfirmationOutcome {
    case proceedOnce
    case proceedAlways
    case cancel
}

struct ToolConfirmationView: View {
    let toolCall: ToolCall
    let onConfirm: (ToolConfirmationOutcome) -> Void
    @State private var showingDiff = false
    @State private var currentContent = ""
    @State private var proposedContent = ""
    @State private var filePath = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("Tool Confirmation Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Divider()
            
            // Tool info
            VStack(alignment: .leading, spacing: 8) {
                if let description = toolCall.description {
                    Text(description)
                        .font(.headline)
                }
                
                if toolCall.name == "write_file",
                   let path = toolCall.arguments["file_path"] as? String,
                   let content = toolCall.arguments["content"] as? String {
                    
                    Text("File: \(path)")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    // Show diff if file exists
                    if FileManager.default.fileExists(atPath: path) {
                        Button("Show Diff") {
                            loadDiff(path: path, newContent: content)
                            showingDiff = true
                        }
                        .buttonStyle(.link)
                    } else {
                        Text("New file will be created")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    // Content preview
                    GroupBox("Content Preview") {
                        ScrollView {
                            Text(content)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .padding(8)
                        }
                        .frame(height: 200)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(4)
                    }
                }
            }
            
            Divider()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onConfirm(.cancel)
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Allow Always") {
                    onConfirm(.proceedAlways)
                }
                
                Button("Allow Once") {
                    onConfirm(.proceedOnce)
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 20)
        .sheet(isPresented: $showingDiff) {
            DiffView(
                filePath: filePath,
                currentContent: currentContent,
                proposedContent: proposedContent
            )
        }
    }
    
    private func loadDiff(path: String, newContent: String) {
        filePath = path
        proposedContent = newContent
        if let current = try? String(contentsOfFile: path) {
            currentContent = current
        } else {
            currentContent = ""
        }
    }
}

struct DiffView: View {
    let filePath: String
    let currentContent: String
    let proposedContent: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Diff: \(URL(fileURLWithPath: filePath).lastPathComponent)")
                    .font(.headline)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Diff content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(generateDiff().enumerated()), id: \.offset) { _, line in
                        DiffLineView(line: line)
                    }
                }
                .padding()
            }
            .background(Color(NSColor.textBackgroundColor))
        }
        .frame(width: 800, height: 600)
    }
    
    private func generateDiff() -> [DiffLine] {
        let currentLines = currentContent.components(separatedBy: .newlines)
        let proposedLines = proposedContent.components(separatedBy: .newlines)
        
        var diff: [DiffLine] = []
        var lineNumber = 1
        
        // Simple line-by-line diff (could be improved with proper diff algorithm)
        let maxLines = max(currentLines.count, proposedLines.count)
        
        for i in 0..<maxLines {
            let currentLine = i < currentLines.count ? currentLines[i] : nil
            let proposedLine = i < proposedLines.count ? proposedLines[i] : nil
            
            if currentLine == proposedLine {
                if let line = currentLine {
                    diff.append(DiffLine(type: .unchanged, content: line, lineNumber: lineNumber))
                    lineNumber += 1
                }
            } else {
                if let line = currentLine {
                    diff.append(DiffLine(type: .removed, content: line, lineNumber: lineNumber))
                }
                if let line = proposedLine {
                    diff.append(DiffLine(type: .added, content: line, lineNumber: lineNumber))
                    lineNumber += 1
                }
            }
        }
        
        return diff
    }
}

struct DiffLine {
    enum LineType {
        case added
        case removed
        case unchanged
        
        var color: Color {
            switch self {
            case .added: return .green.opacity(0.3)
            case .removed: return .red.opacity(0.3)
            case .unchanged: return .clear
            }
        }
        
        var prefix: String {
            switch self {
            case .added: return "+"
            case .removed: return "-"
            case .unchanged: return " "
            }
        }
    }
    
    let type: LineType
    let content: String
    let lineNumber: Int
}

struct DiffLineView: View {
    let line: DiffLine
    
    var body: some View {
        HStack(spacing: 0) {
            Text(line.prefix)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(line.type == .added ? .green : line.type == .removed ? .red : .secondary)
                .frame(width: 20)
            
            Text(String(format: "%4d", line.lineNumber))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40)
            
            Text(line.content)
                .font(.system(size: 12, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(line.type.color)
    }
}