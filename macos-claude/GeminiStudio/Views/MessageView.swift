import SwiftUI
import AppKit

struct MessageView: View {
    let message: Message
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovered = false
    @State private var showingActions = false
    @State private var isCopied = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Avatar(sender: message.sender)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(message.sender == .user ? "You" : "Gemini")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text(message.timestamp.formatted())
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
                    
                    Spacer()
                    
                    if isHovered || showingActions {
                        MessageActions(
                            message: message,
                            isCopied: $isCopied
                        )
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                
                if message.isStreaming {
                    StreamingMessageContent(text: message.content)
                } else {
                    MessageContent(message: message)
                }
                
                if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                    ToolCallsView(toolCalls: toolCalls)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(message.sender == .user ? 
                    themeManager.currentTheme.userMessageColor : 
                    themeManager.currentTheme.assistantMessageColor)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct Avatar: View {
    let sender: Message.Sender
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Group {
                if sender == .user {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor)
                } else {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
            }
            .frame(width: 36, height: 36)
            
            Image(systemName: sender == .user ? "person.fill" : "sparkles")
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
    }
}

struct MessageContent: View {
    let message: Message
    @EnvironmentObject var themeManager: ThemeManager
    @State private var renderedAttributedString: NSAttributedString?
    
    var body: some View {
        Group {
            if message.contentType == .code {
                CodeBlockView(code: message.content, language: message.codeLanguage)
            } else if message.contentType == .markdown {
                MarkdownView(markdown: message.content)
            } else {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .textSelection(.enabled)
            }
        }
    }
}

struct StreamingMessageContent: View {
    let text: String
    @EnvironmentObject var themeManager: ThemeManager
    @State private var visibleText = ""
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            Text(visibleText)
                .font(.system(size: 15))
                .foregroundColor(themeManager.currentTheme.textColor)
                .textSelection(.enabled)
            
            if currentIndex < text.count {
                StreamingCursor()
            }
        }
        .onReceive(timer) { _ in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                visibleText.append(text[index])
                currentIndex += 1
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }
}

struct StreamingCursor: View {
    @State private var opacity = 1.0
    
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 2, height: 16)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    opacity = 0.2
                }
            }
    }
}

struct MessageActions: View {
    let message: Message
    @Binding var isCopied: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            ActionButton(
                icon: isCopied ? "checkmark" : "doc.on.doc",
                action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message.content, forType: .string)
                    withAnimation {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                }
            )
            
            if message.sender == .assistant {
                ActionButton(
                    icon: "arrow.clockwise",
                    action: {
                        // Regenerate response
                    }
                )
            }
            
            ActionButton(
                icon: "ellipsis",
                action: {
                    // Show more options
                }
            )
        }
    }
}

struct ActionButton: View {
    let icon: String
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isHovered ? 
                            themeManager.currentTheme.hoverColor : 
                            Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String?
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let language = language {
                    Text(language)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    withAnimation {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(isCopied ? "Copied!" : "Copy")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.currentTheme.codeHeaderColor)
            
            ScrollView(.horizontal) {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(themeManager.currentTheme.codeTextColor)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .background(themeManager.currentTheme.codeBackgroundColor)
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
    }
}

struct MarkdownView: View {
    let markdown: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        // In a real implementation, this would parse and render markdown
        Text(markdown)
            .font(.system(size: 15))
            .foregroundColor(themeManager.currentTheme.textColor)
            .textSelection(.enabled)
    }
}

struct ToolCallsView: View {
    let toolCalls: [ToolCall]
    @EnvironmentObject var themeManager: ThemeManager
    @State private var expandedTools: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(toolCalls) { toolCall in
                ToolCallRow(
                    toolCall: toolCall,
                    isExpanded: expandedTools.contains(toolCall.id)
                )
                .onTapGesture {
                    withAnimation {
                        if expandedTools.contains(toolCall.id) {
                            expandedTools.remove(toolCall.id)
                        } else {
                            expandedTools.insert(toolCall.id)
                        }
                    }
                }
            }
        }
    }
}

struct ToolCallRow: View {
    let toolCall: ToolCall
    let isExpanded: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: toolCall.status.icon)
                    .font(.system(size: 14))
                    .foregroundColor(toolCall.status.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let description = toolCall.description {
                        Text(description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textColor)
                    } else {
                        Text(toolCall.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                    
                    if toolCall.status == .failed, let result = toolCall.result {
                        Text(result)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.red)
                            .textSelection(.enabled)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                if toolCall.result != nil && toolCall.status != .failed {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.currentTheme.toolCallBackgroundColor)
            )
            
            if isExpanded && toolCall.result != nil && toolCall.status != .failed {
                VStack(alignment: .leading, spacing: 8) {
                    if let result = toolCall.result {
                        ScrollView {
                            VStack(alignment: .leading) {
                                Text(result)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(8)
                        }
                        .frame(maxHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.currentTheme.surfaceColor)
                        )
                    }
                }
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}