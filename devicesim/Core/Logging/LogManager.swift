import os
import Foundation

enum LogCategory: String, CaseIterable {
    case ble = "BLE"
    case jsEngine = "JSEngine"
    case application = "Application"
}

final class LogManager {
    static let shared = LogManager()
    
    private var loggers: [LogCategory: ObservableLogger] = [:]
    
    private init() {
        setupDefaultLoggers()
    }

    private func setupDefaultLoggers() {
        for category in LogCategory.allCases {
            let subsystem = Bundle.main.bundleIdentifier ?? "com.example.app"
            loggers[category] = ObservableLogger(category: category, logger: Logger(subsystem: subsystem, category: category.rawValue))
        }
    }

    func logger(for category: LogCategory) -> ObservableLogger {
        loggers[category]!
    }
}
