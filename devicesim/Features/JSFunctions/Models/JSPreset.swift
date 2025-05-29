import AppKit
import Foundation

struct JSPreset: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let code: String
    let description: String

    init(id: UUID = UUID(), name: String, code: String = "", description: String = "") {
        self.id = id
        self.name = name
        self.description = description
        self.code = code
    }
}