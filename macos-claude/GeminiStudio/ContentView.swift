import SwiftUI

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthService
    @State private var selectedConversationId: UUID?
    @State private var showingNewChat = false
    @State private var sidebarWidth: CGFloat = 280
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if authService.isAuthenticated {
                    HSplitView {
                        SidebarView(
                            conversations: $chatViewModel.conversations,
                            selectedConversationId: $selectedConversationId,
                            showingNewChat: $showingNewChat
                        )
                        .frame(minWidth: 240, idealWidth: sidebarWidth, maxWidth: 400)
                        
                        ChatView(
                            viewModel: chatViewModel,
                            selectedConversationId: $selectedConversationId
                        )
                        .frame(minWidth: 600)
                    }
                    .overlay(alignment: .topTrailing) {
                        StatusBar()
                            .padding()
                    }
                } else {
                    AuthenticationView()
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .onAppear {
            if authService.hasStoredCredentials() {
                authService.attemptAutoLogin()
            }
        }
    }
}

struct SidebarView: View {
    @Binding var conversations: [Conversation]
    @Binding var selectedConversationId: UUID?
    @Binding var showingNewChat: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Conversations")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingNewChat.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            SearchField(text: $searchText)
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredConversations) { conversation in
                        ConversationRow(
                            conversation: conversation,
                            isSelected: selectedConversationId == conversation.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedConversationId = conversation.id
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .background(themeManager.currentTheme.sidebarColor)
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: conversation.icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                    .lineLimit(1)
                
                Text(conversation.lastMessage)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : themeManager.currentTheme.secondaryTextColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(conversation.formattedDate)
                .font(.system(size: 11))
                .foregroundColor(isSelected ? .white.opacity(0.7) : themeManager.currentTheme.tertiaryTextColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? themeManager.currentTheme.accentColor : 
                      isHovered ? themeManager.currentTheme.hoverColor : Color.clear)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var selectedConversationId: UUID?
    @EnvironmentObject var themeManager: ThemeManager
    @State private var inputText = ""
    @State private var showingToolPanel = false
    
    var body: some View {
        VStack(spacing: 0) {
            ChatHeader(
                title: viewModel.currentConversation?.title ?? "New Conversation",
                showingToolPanel: $showingToolPanel
            )
            
            Divider()
            
            if let conversation = viewModel.currentConversation {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(conversation.messages) { message in
                                MessageView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: conversation.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(conversation.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
            } else {
                EmptyStateView()
            }
            
            Divider()
            
            InputBar(
                text: $inputText,
                onSend: {
                    viewModel.sendMessage(inputText)
                    inputText = ""
                }
            )
            .padding()
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
}

struct ChatHeader: View {
    let title: String
    @Binding var showingToolPanel: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { showingToolPanel.toggle() }) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

struct SearchField: View {
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
            
            TextField("Search conversations...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.currentTheme.inputBackgroundColor)
        )
    }
}

struct InputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isExpanded = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            HStack {
                Image(systemName: "paperclip")
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
                    .onTapGesture {
                        // Handle file attachment
                    }
                
                TextEditor(text: $text)
                    .font(.system(size: 15))
                    .frame(minHeight: 40, maxHeight: isExpanded ? 200 : 80)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .onChange(of: text) { newValue in
                        withAnimation {
                            isExpanded = newValue.split(separator: "\n").count > 2
                        }
                    }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.inputBackgroundColor)
            )
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(text.isEmpty ? 
                        themeManager.currentTheme.tertiaryTextColor : 
                        themeManager.currentTheme.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
        }
    }
}

struct StatusBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var connectionStatus: ConnectionStatus = .connected
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Circle()
                    .fill(connectionStatus.color)
                    .frame(width: 8, height: 8)
                
                Text(connectionStatus.text)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            Text("Model: \(UserDefaults.standard.string(forKey: "selectedModel") ?? "gemini-2.5-flash")")
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(themeManager.currentTheme.surfaceColor)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct EmptyStateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "message.circle")
                .font(.system(size: 64))
                .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
            
            Text("Start a new conversation")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("Ask questions, get help with code, or explore ideas")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @State private var apiKey = ""
    @State private var authMethod: AuthService.AuthMethod = .geminiAPI
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Authentication Required")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                Picker("Authentication Method", selection: $authMethod) {
                    Text("Gemini API Key").tag(AuthService.AuthMethod.geminiAPI)
                    Text("Google OAuth").tag(AuthService.AuthMethod.googleOAuth)
                    Text("Vertex AI").tag(AuthService.AuthMethod.vertexAI)
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
                
                if authMethod == .geminiAPI {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        SecureField("Enter your Gemini API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 400)
                    }
                }
                
                Button(action: {
                    authService.authenticate(method: authMethod, apiKey: apiKey)
                }) {
                    Text("Authenticate")
                        .frame(width: 200)
                        .padding(.vertical, 12)
                        .background(themeManager.currentTheme.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

enum ConnectionStatus {
    case connected, connecting, disconnected
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .red
        }
    }
    
    var text: String {
        switch self {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        }
    }
}