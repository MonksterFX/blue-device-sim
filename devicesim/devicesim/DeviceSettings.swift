import Foundation

class DeviceSettings: ObservableObject {
    @Published var deviceName: String = "MacOS Simulator"
    @Published var serviceUUID: String = "5FFE0000-5000-4000-3000-200000000000"
    @Published var characteristicUUID: String = "5FFE0001-5000-4000-3000-200000000000"
    @Published var autoResponse: Bool = true
    @Published var autoResponseText: String = "Hello from MacOS Simulator!"
    
    // Saved message templates for quick sending
    @Published var savedMessages: [String] = [
        "Hello!",
        "Test message",
        "Status: OK",
        "Battery: 100%"
    ]
    
    func addSavedMessage(_ message: String) {
        guard !message.isEmpty, !savedMessages.contains(message) else { return }
        savedMessages.append(message)
    }
    
    func removeSavedMessage(at index: Int) {
        guard savedMessages.indices.contains(index) else { return }
        savedMessages.remove(at: index)
    }
} 