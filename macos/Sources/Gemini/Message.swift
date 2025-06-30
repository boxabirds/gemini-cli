import Foundation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
