import SwiftUI

@MainActor
class ThemeManager: ObservableObject {
    @Published var selectedTheme: Theme = .default {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    var currentTheme: ThemeProtocol {
        switch selectedTheme {
        case .default:
            return DefaultTheme()
        case .dark:
            return DarkTheme()
        case .light:
            return LightTheme()
        case .midnight:
            return MidnightTheme()
        }
    }
    
    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = Theme(rawValue: savedTheme) {
            selectedTheme = theme
        }
    }
    
    enum Theme: String, CaseIterable {
        case `default` = "default"
        case dark = "dark"
        case light = "light"
        case midnight = "midnight"
        
        var displayName: String {
            switch self {
            case .default: return "System"
            case .dark: return "Dark"
            case .light: return "Light"
            case .midnight: return "Midnight"
            }
        }
    }
}

protocol ThemeProtocol {
    var backgroundColor: Color { get }
    var surfaceColor: Color { get }
    var sidebarColor: Color { get }
    var textColor: Color { get }
    var secondaryTextColor: Color { get }
    var tertiaryTextColor: Color { get }
    var accentColor: Color { get }
    var userMessageColor: Color { get }
    var assistantMessageColor: Color { get }
    var hoverColor: Color { get }
    var borderColor: Color { get }
    var inputBackgroundColor: Color { get }
    var codeBackgroundColor: Color { get }
    var codeTextColor: Color { get }
    var codeHeaderColor: Color { get }
    var toolCallBackgroundColor: Color { get }
}

struct DefaultTheme: ThemeProtocol {
    var backgroundColor: Color { Color(NSColor.windowBackgroundColor) }
    var surfaceColor: Color { Color(NSColor.controlBackgroundColor) }
    var sidebarColor: Color { Color(NSColor.controlBackgroundColor).opacity(0.95) }
    var textColor: Color { Color(NSColor.labelColor) }
    var secondaryTextColor: Color { Color(NSColor.secondaryLabelColor) }
    var tertiaryTextColor: Color { Color(NSColor.tertiaryLabelColor) }
    var accentColor: Color { Color.accentColor }
    var userMessageColor: Color { Color(NSColor.controlBackgroundColor) }
    var assistantMessageColor: Color { Color(NSColor.controlBackgroundColor).opacity(0.8) }
    var hoverColor: Color { Color(NSColor.selectedContentBackgroundColor).opacity(0.1) }
    var borderColor: Color { Color(NSColor.separatorColor) }
    var inputBackgroundColor: Color { Color(NSColor.textBackgroundColor) }
    var codeBackgroundColor: Color { Color(NSColor.textBackgroundColor) }
    var codeTextColor: Color { Color(NSColor.labelColor) }
    var codeHeaderColor: Color { Color(NSColor.windowBackgroundColor) }
    var toolCallBackgroundColor: Color { Color(NSColor.controlBackgroundColor).opacity(0.5) }
}

struct DarkTheme: ThemeProtocol {
    var backgroundColor: Color { Color(red: 0.11, green: 0.11, blue: 0.12) }
    var surfaceColor: Color { Color(red: 0.15, green: 0.15, blue: 0.17) }
    var sidebarColor: Color { Color(red: 0.09, green: 0.09, blue: 0.10) }
    var textColor: Color { Color.white }
    var secondaryTextColor: Color { Color.white.opacity(0.7) }
    var tertiaryTextColor: Color { Color.white.opacity(0.5) }
    var accentColor: Color { Color(red: 0.2, green: 0.6, blue: 1.0) }
    var userMessageColor: Color { Color(red: 0.2, green: 0.2, blue: 0.22) }
    var assistantMessageColor: Color { Color(red: 0.15, green: 0.15, blue: 0.17) }
    var hoverColor: Color { Color.white.opacity(0.05) }
    var borderColor: Color { Color.white.opacity(0.1) }
    var inputBackgroundColor: Color { Color(red: 0.13, green: 0.13, blue: 0.14) }
    var codeBackgroundColor: Color { Color(red: 0.08, green: 0.08, blue: 0.09) }
    var codeTextColor: Color { Color(red: 0.8, green: 0.8, blue: 0.8) }
    var codeHeaderColor: Color { Color(red: 0.1, green: 0.1, blue: 0.11) }
    var toolCallBackgroundColor: Color { Color(red: 0.13, green: 0.13, blue: 0.14) }
}

struct LightTheme: ThemeProtocol {
    var backgroundColor: Color { Color.white }
    var surfaceColor: Color { Color(red: 0.98, green: 0.98, blue: 0.98) }
    var sidebarColor: Color { Color(red: 0.96, green: 0.96, blue: 0.96) }
    var textColor: Color { Color.black }
    var secondaryTextColor: Color { Color.black.opacity(0.7) }
    var tertiaryTextColor: Color { Color.black.opacity(0.5) }
    var accentColor: Color { Color(red: 0.0, green: 0.5, blue: 1.0) }
    var userMessageColor: Color { Color(red: 0.95, green: 0.95, blue: 0.95) }
    var assistantMessageColor: Color { Color.white }
    var hoverColor: Color { Color.black.opacity(0.05) }
    var borderColor: Color { Color.black.opacity(0.1) }
    var inputBackgroundColor: Color { Color(red: 0.98, green: 0.98, blue: 0.98) }
    var codeBackgroundColor: Color { Color(red: 0.97, green: 0.97, blue: 0.97) }
    var codeTextColor: Color { Color.black }
    var codeHeaderColor: Color { Color(red: 0.94, green: 0.94, blue: 0.94) }
    var toolCallBackgroundColor: Color { Color(red: 0.96, green: 0.96, blue: 0.96) }
}

struct MidnightTheme: ThemeProtocol {
    var backgroundColor: Color { Color(red: 0.05, green: 0.05, blue: 0.08) }
    var surfaceColor: Color { Color(red: 0.08, green: 0.08, blue: 0.12) }
    var sidebarColor: Color { Color(red: 0.03, green: 0.03, blue: 0.05) }
    var textColor: Color { Color(red: 0.9, green: 0.9, blue: 0.95) }
    var secondaryTextColor: Color { Color(red: 0.7, green: 0.7, blue: 0.8) }
    var tertiaryTextColor: Color { Color(red: 0.5, green: 0.5, blue: 0.6) }
    var accentColor: Color { Color(red: 0.4, green: 0.4, blue: 1.0) }
    var userMessageColor: Color { Color(red: 0.1, green: 0.1, blue: 0.15) }
    var assistantMessageColor: Color { Color(red: 0.08, green: 0.08, blue: 0.12) }
    var hoverColor: Color { Color(red: 0.2, green: 0.2, blue: 0.3).opacity(0.3) }
    var borderColor: Color { Color(red: 0.2, green: 0.2, blue: 0.3) }
    var inputBackgroundColor: Color { Color(red: 0.06, green: 0.06, blue: 0.09) }
    var codeBackgroundColor: Color { Color(red: 0.02, green: 0.02, blue: 0.04) }
    var codeTextColor: Color { Color(red: 0.8, green: 0.8, blue: 0.9) }
    var codeHeaderColor: Color { Color(red: 0.04, green: 0.04, blue: 0.06) }
    var toolCallBackgroundColor: Color { Color(red: 0.06, green: 0.06, blue: 0.09) }
}