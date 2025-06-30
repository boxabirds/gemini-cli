import SwiftUI

extension View {
    func glassBackground() -> some View {
        self
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    func shimmer() -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width)
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
                }
                .mask(self)
            )
    }
    
    func fadeInAnimation() -> some View {
        self
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeOut(duration: 0.3), value: UUID())
    }
    
    func bounceEffect() -> some View {
        self
            .animation(.interpolatingSpring(stiffness: 300, damping: 15), value: UUID())
    }
    
    func softShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
    }
}

extension Color {
    static var randomGradient: LinearGradient {
        let colors = [
            [Color.blue, Color.purple],
            [Color.orange, Color.pink],
            [Color.green, Color.teal],
            [Color.purple, Color.pink],
            [Color.red, Color.orange]
        ].randomElement()!
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}

extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    var chatTimestamp: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(self) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(self) {
            return "Yesterday"
        } else if Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
        } else {
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: self)
    }
}

// MARK: - Custom View Modifiers

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct TypewriterEffect: ViewModifier {
    let text: String
    @State private var displayedText = ""
    @State private var currentIndex = 0
    let speed: Double
    
    func body(content: Content) -> some View {
        Text(displayedText)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
                    if currentIndex < text.count {
                        let index = text.index(text.startIndex, offsetBy: currentIndex)
                        displayedText.append(text[index])
                        currentIndex += 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
    }
}

extension View {
    func pulse() -> some View {
        modifier(PulseEffect())
    }
    
    func typewriter(text: String, speed: Double = 0.05) -> some View {
        modifier(TypewriterEffect(text: text, speed: speed))
    }
}