import os
import SwiftUI
import Foundation

protocol LogStoreMessageProtocol {
    var id: UUID {get}
    var timestamp: Date {get}
    var message: String {get}
    var level: OSLogType {get}
}

struct LogStoreMessage: Identifiable, LogStoreMessageProtocol {
    let id: UUID
    let timestamp: Date
    let message: String
    let level: OSLogType
}

@Observable
class LogStore {
    var logs: [LogStoreMessage] = []

    func add(_ message: String, _ level: OSLogType) {
        DispatchQueue.main.async {
            self.logs.append(LogStoreMessage(id: UUID(), timestamp: Date(), message: message, level: level))
        }
    }
}
