import os
import Foundation

class ObservableLogger {
    let logger: Logger
    let logStore: LogStore
    let category: LogCategory

    init(category: LogCategory, logger: Logger) {
        self.logStore = LogStore()
        self.category = category
        self.logger = logger
    }

    func debug(_ message: String) {
        logger.debug("\(message)")
        logStore.add(message, .debug)
    }

    func info(_ message: String) {
        logger.info("\(message)")
        logStore.add(message, .info)
    }

    func error(_ message: String) {
        logger.error("\(message)")
        logStore.add(message, .error)
    }
}


