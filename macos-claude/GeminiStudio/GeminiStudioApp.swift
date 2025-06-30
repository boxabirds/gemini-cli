import SwiftUI

@main
struct GeminiStudioApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var authService = AuthService()
    @State private var showingSplash = true
    
    var body: some Scene {
        WindowGroup {
            if showingSplash {
                SplashView()
                    .frame(width: 800, height: 600)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showingSplash = false
                            }
                        }
                    }
            } else {
                ContentView()
                    .environmentObject(themeManager)
                    .environmentObject(authService)
                    .frame(minWidth: 1200, minHeight: 800)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Settings...") {
                    NSApp.sendAction(#selector(AppDelegate.showSettings), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(themeManager)
                .environmentObject(authService)
        }
    }
}

struct SplashView: View {
    @State private var animationAmount = 0.0
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 30) {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.5), radius: 20)
                    .scaleEffect(animationAmount)
                    .opacity(opacity)
                
                Text("Gemini Studio")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                Text("AI-Powered Development")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationAmount = 1.0
                opacity = 1.0
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @objc func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}