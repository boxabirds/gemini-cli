import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = SettingsTab.general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case appearance = "Appearance"
        case models = "Models"
        case tools = "Tools"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .appearance: return "paintbrush"
            case .models: return "cpu"
            case .tools: return "wrench.and.screwdriver"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .frame(width: 200)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView()
                    case .appearance:
                        AppearanceSettingsView()
                    case .models:
                        ModelsSettingsView()
                    case .tools:
                        ToolsSettingsView()
                    case .advanced:
                        AdvancedSettingsView()
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 800, height: 600)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("autoSaveConversations") private var autoSaveConversations = true
    @AppStorage("showWelcomeScreen") private var showWelcomeScreen = true
    @AppStorage("enableSoundEffects") private var enableSoundEffects = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("General")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Auto-save conversations", isOn: $autoSaveConversations)
                    Toggle("Show welcome screen on startup", isOn: $showWelcomeScreen)
                    Toggle("Enable sound effects", isOn: $enableSoundEffects)
                }
                .padding()
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Authentication Status:")
                            .fontWeight(.medium)
                        Text(authService.isAuthenticated ? "Connected" : "Not Connected")
                            .foregroundColor(authService.isAuthenticated ? .green : .red)
                    }
                    
                    if authService.isAuthenticated {
                        Button("Sign Out") {
                            authService.signOut()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
        }
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("windowTransparency") private var windowTransparency = 0.0
    @AppStorage("useSystemAccentColor") private var useSystemAccentColor = true
    @State private var customAccentColor = Color.blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Appearance")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            GroupBox("Theme") {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Color Theme", selection: $themeManager.selectedTheme) {
                        ForEach(ThemeManager.Theme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                    
                    HStack {
                        Text("Window Transparency")
                        Slider(value: $windowTransparency, in: 0...1)
                            .frame(width: 200)
                        Text("\(Int(windowTransparency * 100))%")
                            .monospacedDigit()
                    }
                    
                    Toggle("Use system accent color", isOn: $useSystemAccentColor)
                    
                    if !useSystemAccentColor {
                        ColorPicker("Custom accent color", selection: $customAccentColor)
                    }
                }
                .padding()
            }
            
            GroupBox("Preview") {
                MessagePreview()
                    .padding()
            }
        }
    }
}

struct MessagePreview: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(themeManager.currentTheme.accentColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    )
                
                VStack(alignment: .leading) {
                    Text("You")
                        .font(.system(size: 13, weight: .semibold))
                    Text("How does quantum computing work?")
                        .font(.system(size: 14))
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.currentTheme.userMessageColor)
            )
            
            HStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    )
                
                VStack(alignment: .leading) {
                    Text("Gemini")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Quantum computing leverages quantum mechanics...")
                        .font(.system(size: 14))
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.currentTheme.assistantMessageColor)
            )
        }
    }
}

struct ModelsSettingsView: View {
    @AppStorage("selectedModel") private var selectedModel = "gemini-2.5-flash"
    @AppStorage("temperature") private var temperature = 0.7
    @AppStorage("maxTokens") private var maxTokens = 4096.0
    @AppStorage("topP") private var topP = 0.9
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Models")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            GroupBox("Model Selection") {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Model", selection: $selectedModel) {
                        Text("Gemini 2.5 Flash").tag("gemini-2.5-flash")
                        Text("Gemini 2.5 Pro").tag("gemini-2.5-pro")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 250)
                    
                    Text("Selected model: \(selectedModel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            GroupBox("Model Parameters") {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.2f", temperature))
                                .monospacedDigit()
                        }
                        Slider(value: $temperature, in: 0...1)
                        Text("Controls randomness in responses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Tokens")
                            Spacer()
                            Text("\(Int(maxTokens))")
                                .monospacedDigit()
                        }
                        Slider(value: $maxTokens, in: 256...8192, step: 256)
                        Text("Maximum length of generated responses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Top P")
                            Spacer()
                            Text(String(format: "%.2f", topP))
                                .monospacedDigit()
                        }
                        Slider(value: $topP, in: 0...1)
                        Text("Nucleus sampling threshold")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
    }
}

struct ToolsSettingsView: View {
    @AppStorage("enableFileOperations") private var enableFileOperations = true
    @AppStorage("enableWebSearch") private var enableWebSearch = true
    @AppStorage("enableCodeExecution") private var enableCodeExecution = false
    @AppStorage("requireToolConfirmation") private var requireToolConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Tools")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            GroupBox("Available Tools") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Enable file operations", isOn: $enableFileOperations)
                    Toggle("Enable web search", isOn: $enableWebSearch)
                    Toggle("Enable code execution", isOn: $enableCodeExecution)
                    
                    Divider()
                    
                    Toggle("Require confirmation before tool use", isOn: $requireToolConfirmation)
                }
                .padding()
            }
            
            GroupBox("Tool Permissions") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("File System Access:")
                        Spacer()
                        Text(enableFileOperations ? "Enabled" : "Disabled")
                            .foregroundColor(enableFileOperations ? .green : .red)
                    }
                    
                    if enableFileOperations {
                        Text("Allowed directories:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• ~/Documents\n• ~/Downloads\n• ~/Desktop")
                            .font(.system(size: 12, design: .monospaced))
                            .padding(.leading)
                    }
                }
                .padding()
            }
        }
    }
}

struct AdvancedSettingsView: View {
    @AppStorage("enableDebugMode") private var enableDebugMode = false
    @AppStorage("logLevel") private var logLevel = "info"
    @AppStorage("cacheSize") private var cacheSize = 100.0
    @State private var showingResetAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Advanced")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            GroupBox("Developer Options") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Enable debug mode", isOn: $enableDebugMode)
                    
                    Picker("Log Level", selection: $logLevel) {
                        Text("Error").tag("error")
                        Text("Warning").tag("warning")
                        Text("Info").tag("info")
                        Text("Debug").tag("debug")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                .padding()
            }
            
            GroupBox("Cache") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text("\(Int(cacheSize)) MB")
                            .monospacedDigit()
                    }
                    
                    Slider(value: $cacheSize, in: 50...500, step: 50)
                    
                    Button("Clear Cache") {
                        // Clear cache
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            
            GroupBox("Reset") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reset all settings to defaults")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Reset Settings") {
                        showingResetAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.red)
                }
                .padding()
            }
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                // Reset all settings
            }
        } message: {
            Text("Are you sure you want to reset all settings to their default values? This action cannot be undone.")
        }
    }
}