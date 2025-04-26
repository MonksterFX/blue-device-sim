import Foundation
import CoreBluetooth
import Combine
import AppKit

struct LogMessage: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let message: String
    
    var formattedTimestamp: String {
        timestamp.formatted(date: .omitted, time: .standard)
    }
    
    var fullMessage: String {
        "[\(formattedTimestamp)] \(message)"
    }
}

class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isAdvertising = false
    @Published var connectedCentrals: [CBCentral] = []
    @Published var logMessages: [LogMessage] = []
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var stateMessage: String = "Initializing Bluetooth..."
    
    // MARK: - Device Settings
    var deviceSettings: DeviceSettings?
    
    // MARK: - Peripheral Manager
    private var peripheralManager: CBPeripheralManager!
    private var isInitialized = false
    
    // MARK: - Service and Characteristic UUIDs
    private var serviceUUID: CBUUID {
        guard let settings = deviceSettings else {
            return CBUUID(string: "5FFE0000-5000-4000-3000-200000000000")
        }
        return CBUUID(string: settings.serviceUUID)
    }
    
    private var characteristicUUID: CBUUID {
        guard let settings = deviceSettings else {
            return CBUUID(string: "5FFE0001-5000-4000-3000-200000000000")
        }
        return CBUUID(string: settings.characteristicUUID)
    }
    
    // MARK: - Properties
    private var transferCharacteristic: CBMutableCharacteristic!
    private var transferService: CBMutableService!
    private var dataToSend = Data()
    private var sendDataIndex: Int = 0
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else {
            let errorMessage = "Cannot start advertising - Bluetooth is not powered on (Current state: \(stateDescription(for: peripheralManager.state)))"
            addLog(errorMessage)
            
            // Provide more helpful diagnostics
            if peripheralManager.state == .unauthorized {
                addLog("Bluetooth permission denied. Please check System Settings > Privacy & Security > Bluetooth")
            } else if peripheralManager.state == .poweredOff {
                addLog("Bluetooth is turned off. Please turn on Bluetooth in System Settings or Control Center")
            }
            
            return
        }
        
        if !peripheralManager.isAdvertising {
            setupService()
            
            // Get device name from settings or use default
            let deviceName = deviceSettings?.deviceName ?? "MacOS Simulator"
            
            // Start advertising with a custom name
            peripheralManager.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
                CBAdvertisementDataLocalNameKey: deviceName
            ])
            
            addLog("Started advertising as '\(deviceName)'")
            isAdvertising = true
        }
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        addLog("Stopped advertising")
        isAdvertising = false
    }
    
    func sendData(_ data: Data) {
        guard !connectedCentrals.isEmpty else {
            addLog("No devices connected")
            return
        }
        
        let didSend = peripheralManager.updateValue(
            data,
            for: transferCharacteristic,
            onSubscribedCentrals: nil
        )
        
        if didSend {
            addLog("Sent data: \(String(data: data, encoding: .utf8) ?? "Unknown")")
        } else {
            addLog("Failed to send data")
        }
    }
    
    // Helper method to get human-readable Bluetooth state
    private func stateDescription(for state: CBManagerState) -> String {
        switch state {
        case .poweredOn: return "Powered On"
        case .poweredOff: return "Powered Off"
        case .resetting: return "Resetting"
        case .unauthorized: return "Unauthorized/Permission Denied"
        case .unsupported: return "Unsupported"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown (\(state.rawValue))"
        }
    }
    
    // MARK: - Private Methods
    private func setupService() {
        // Create a characteristic
        transferCharacteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )
        
        // Create a service
        transferService = CBMutableService(
            type: serviceUUID,
            primary: true
        )
        
        // Add the characteristic to the service
        transferService.characteristics = [transferCharacteristic]
        
        // Add the service to the peripheral manager
        peripheralManager.add(transferService)
        
        addLog("Service setup complete")
    }
    
    private func addLog(_ message: String) {
        DispatchQueue.main.async {
            let logMessage = LogMessage(timestamp: Date(), message: message)
            self.logMessages.append(logMessage)
            
            // Keep log size manageable
            if self.logMessages.count > 100 {
                self.logMessages.removeFirst(self.logMessages.count - 100)
            }
        }
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        self.bluetoothState = peripheral.state
        
        switch peripheral.state {
        case .poweredOn:
            stateMessage = "Bluetooth is powered on"
            addLog("Bluetooth is powered on")
        case .poweredOff:
            stateMessage = "Bluetooth is powered off - Please turn on Bluetooth"
            addLog("Bluetooth is powered off")
            isAdvertising = false
        case .resetting:
            stateMessage = "Bluetooth is resetting"
            addLog("Bluetooth is resetting")
        case .unauthorized:
            stateMessage = "Bluetooth permission denied - Check System Settings"
            addLog("Bluetooth is unauthorized - Check System Settings > Privacy & Security > Bluetooth")
        case .unsupported:
            stateMessage = "Bluetooth is not supported on this device"
            addLog("Bluetooth is not supported")
        case .unknown:
            stateMessage = "Bluetooth state is unknown"
            addLog("Bluetooth state is unknown")
        @unknown default:
            stateMessage = "Unknown Bluetooth state"
            addLog("Unknown Bluetooth state")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            addLog("Error adding service: \(error.localizedDescription)")
        } else {
            addLog("Service added successfully")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            addLog("Error advertising: \(error.localizedDescription)")
            isAdvertising = false
        } else {
            addLog("Advertising started successfully")
            isAdvertising = true
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        addLog("Central \(central.identifier.uuidString) subscribed to characteristic")
        
        self.connectedCentrals.append(central)
        
        // Send a welcome message
        let welcomeData = "Welcome to MacOS Bluetooth Simulator!".data(using: .utf8)!
        sendData(welcomeData)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        addLog("Central \(central.identifier.uuidString) unsubscribed from characteristic")
        
        self.connectedCentrals.removeAll { $0.identifier == central.identifier }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        // Use auto response from settings if available
        let responseText = deviceSettings?.autoResponseText ?? "Hello from Mac simulator!"
        let response = responseText.data(using: .utf8)!
        
        if request.characteristic.uuid == characteristicUUID {
            request.value = response
            peripheral.respond(to: request, withResult: .success)
            addLog("Responded to read request with: \(responseText)")
        } else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            addLog("Read request for unknown characteristic")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let value = request.value, request.characteristic.uuid == characteristicUUID {
                let stringValue = String(data: value, encoding: .utf8) ?? "Unknown format data"
                addLog("Received write: \(stringValue)")
                
                // Echo back the data to the central as a notification
                sendData(value)
            }
        }
        
        // Respond to the request
        peripheral.respond(to: requests.first!, withResult: .success)
    }
} 
