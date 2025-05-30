import SwiftUI
import Foundation

struct ExtendeLogStoreMessage: LogStoreMessageProtocol{
    let id: UUID
    let timestamp: Date
    let message: String
    let category: LogCategory
}

@Observable
class LogPageViewModel {
    var selectedCategory: LogCategory? = nil
    var logStores: [LogCategory: LogStore] = [:]

    init() {
        for category in LogCategory.allCases {
            logStores[category] = LogManager.shared.logger(for: category).logStore
        }
    }

    var logsSorted: [ExtendeLogStoreMessage] {
        if selectedCategory == nil {
            return logStores.flatMap { category, store in
                store.logs.map { log in
                    ExtendeLogStoreMessage(id: log.id, timestamp: log.timestamp, message: log.message, category: category)
                }
            }.sorted { $0.timestamp < $1.timestamp }
        } else {
            return logStores[selectedCategory!]!.logs.map { log in
                ExtendeLogStoreMessage(id: log.id, timestamp: log.timestamp, message: log.message, category: selectedCategory!)
            }.sorted { $0.timestamp < $1.timestamp }
        }
    }

    func addLog(message: String) {
        if selectedCategory != nil {
            logStores[selectedCategory!]!.add(message)
        }
    }
}
