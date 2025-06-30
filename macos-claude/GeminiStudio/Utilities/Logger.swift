import Foundation
import os.log

class Logger {
    static let shared = Logger()
    private let subsystem = "com.gemini.studio"
    
    private let general = OSLog(subsystem: "com.gemini.studio", category: "general")
    private let api = OSLog(subsystem: "com.gemini.studio", category: "api")
    private let ui = OSLog(subsystem: "com.gemini.studio", category: "ui")
    private let auth = OSLog(subsystem: "com.gemini.studio", category: "auth")
    
    private init() {}
    
    func log(_ message: String, category: LogCategory = .general, type: OSLogType = .default) {
        let log = getLog(for: category)
        os_log("%{public}@", log: log, type: type, message)
        
        // Also print to console for debugging
        #if DEBUG
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(timestamp)] [\(category.rawValue)] \(message)")
        #endif
    }
    
    func error(_ message: String, category: LogCategory = .general) {
        log(message, category: category, type: .error)
    }
    
    func debug(_ message: String, category: LogCategory = .general) {
        log(message, category: category, type: .debug)
    }
    
    func info(_ message: String, category: LogCategory = .general) {
        log(message, category: category, type: .info)
    }
    
    private func getLog(for category: LogCategory) -> OSLog {
        switch category {
        case .general: return general
        case .api: return api
        case .ui: return ui
        case .auth: return auth
        }
    }
    
    enum LogCategory: String {
        case general
        case api
        case ui
        case auth
    }
}

// Convenience functions
func log(_ message: String, category: Logger.LogCategory = .general) {
    Logger.shared.log(message, category: category)
}

func logError(_ message: String, category: Logger.LogCategory = .general) {
    Logger.shared.error(message, category: category)
}

func logDebug(_ message: String, category: Logger.LogCategory = .general) {
    Logger.shared.debug(message, category: category)
}