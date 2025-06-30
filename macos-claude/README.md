# Gemini Studio for macOS

A beautifully designed macOS application that brings the power of Google's Gemini AI to your desktop with an elegant, native interface inspired by Jony Ive's design philosophy.

## Features

### 🎨 Beautiful Design
- Native SwiftUI interface with smooth animations
- Multiple themes including System, Dark, Light, and Midnight
- Glass morphism effects and subtle shadows
- Responsive layout that adapts to window size

### 💬 Advanced Chat Interface
- Real-time streaming responses with typewriter effect
- Syntax highlighting for code blocks
- Markdown rendering support
- Message actions (copy, regenerate, etc.)
- Conversation history with search

### 🛠 Powerful Tools
- File operations (read, write, list, create directories)
- Web search integration
- Command execution (with safety checks)
- Tool confirmation dialogs for security

### 🔐 Security & Privacy
- Secure API key storage in macOS Keychain
- Sandboxed application with limited file system access
- Tool execution requires user confirmation
- Support for multiple authentication methods

### ⚙️ Customization
- Model selection (Gemini 2.5 Flash/Pro, Gemini 1.5 Pro)
- Adjustable parameters (temperature, max tokens, top-p)
- Theme customization with accent colors
- Window transparency settings

## Installation

1. Open the project in Xcode 15 or later
2. Build and run the project (⌘+R)
3. On first launch, you'll be prompted to authenticate with your Gemini API key

## Usage

### Getting Started
1. Launch Gemini Studio
2. Enter your Gemini API key when prompted
3. Start a new conversation or select an existing one
4. Type your message and press Enter or click the send button

### Keyboard Shortcuts
- `⌘+N` - New conversation
- `⌘+,` - Open settings
- `⌘+K` - Search conversations
- `⌘+Enter` - Send message

### Tool Usage
When Gemini needs to use tools (file operations, web search, etc.), you'll see:
- Tool cards showing the tool name and status
- Confirmation dialogs for sensitive operations
- Real-time execution progress
- Results displayed inline

## Architecture

The app follows MVVM architecture with:
- **Views**: SwiftUI views for the UI
- **ViewModels**: Business logic and state management
- **Services**: API communication, file operations, authentication
- **Utilities**: Theme management, extensions, helpers

## Requirements

- macOS 14.0 or later
- Xcode 15 or later
- Gemini API key (get one at https://makersuite.google.com/app/apikey)

## Privacy

Gemini Studio respects your privacy:
- API keys are stored securely in the macOS Keychain
- No telemetry or analytics
- All data stays on your device
- Network requests only to Google's Gemini API

## Credits

Created with inspiration from Apple's design philosophy and the original Gemini CLI project.