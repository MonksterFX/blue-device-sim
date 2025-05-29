import Foundation
import CoreBluetooth
import Combine

class CharacteristicHandlerManager: ObservableObject {
    /// Dictionary of characteristic handlers keyed by UUID string
    @Published private(set) var handlers: [String: CharacteristicHandler] = [:]
    
    /// The Bluetooth manager used to send notifications
    private weak var bluetoothManager: BluetoothManager?
    
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }
    
    /// Adds a new characteristic handler
    func addHandler(characteristicUUID: String, jsReadFunction: String, jsWriteFunction: String, notifyInterval: TimeInterval = 1.0) {
        let handler = CharacteristicHandler(
            characteristicUUID: characteristicUUID,
            jsReadFunction: jsReadFunction,
            jsWriteFunction: jsWriteFunction,
            notifyInterval: notifyInterval
        )
        handlers[characteristicUUID] = handler
    }
    
    /// Removes a characteristic handler
    func removeHandler(characteristicUUID: String) {
        if let handler = handlers[characteristicUUID] {
            handler.stopNotifications()
            handlers.removeValue(forKey: characteristicUUID)
        }
    }
    
    /// Handles a device subscribing to a characteristic
    func handleSubscription(characteristic: CBMutableCharacteristic) {
        guard let handler = handlers[characteristic.uuid.uuidString] else { return }
        
        // Update subscription time
        handler.handleSubscription()
        
        // Start notifications
        handler.startNotifications { [weak self] data in
            self?.bluetoothManager?.sendData(data, characteristic: characteristic)
        }
        
        // No need to update the handler in the dictionary since it's a class (reference type)
    }
    
    /// Handles a device unsubscribing from a characteristic
    func handleUnsubscription(characteristicUUID: String) {
        guard let handler = handlers[characteristicUUID] else { return }
        handler.stopNotifications()
    }
    
    /// Handles a read request for a characteristic
    func handleReadRequest(characteristicUUID: String) -> Data? {
        guard let handler = handlers[characteristicUUID] else { return nil }
        return handler.handleReadRequest()
    }
    
    /// Handles a write request for a characteristic
    func handleWriteRequest(characteristicUUID: String, value: String) -> Data? {
        guard let handler = handlers[characteristicUUID] else { return nil }
        return handler.handleWriteRequest(value: value)
    }
    
    /// Updates the JavaScript function for a handler
    func updateHandler(characteristicUUID: String, jsReadFunction: String, jsWriteFunction: String, notifyInterval: TimeInterval? = nil) {
        if handlers[characteristicUUID] != nil {
            let interval = notifyInterval ?? handlers[characteristicUUID]!.notifyInterval
            let handler = CharacteristicHandler(
                characteristicUUID: characteristicUUID,
                jsReadFunction: jsReadFunction,
                jsWriteFunction: jsWriteFunction,
                notifyInterval: interval
            )
            handlers[characteristicUUID] = handler
        } else {
            addHandler(
                characteristicUUID: characteristicUUID,
                jsReadFunction: jsReadFunction,
                jsWriteFunction: jsWriteFunction,
                notifyInterval: notifyInterval ?? 1.0
            )
        }
    }
    
    /// Clean up all handlers
    func stopAllHandlers() {
        for (_, handler) in handlers {
            handler.stopNotifications()
        }
    }
} 