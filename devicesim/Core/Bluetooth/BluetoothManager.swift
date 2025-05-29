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
    private var profilesViewModel: ProfilesViewModel = ProfilesViewModel()
    
    // MARK: - Published Properties
    @Published var isAdvertising = false
    @Published var connectedCentrals: [CBCentral] = []
    @Published var logMessages: [LogMessage] = []
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var stateMessage: String = "Initializing Bluetooth..."

    // MARK: - Device Settings
    @Published var profile: CustomBleProfile

    // MARK: - Characteristic Handler Manager
    private lazy var characteristicHandlerManager = CharacteristicHandlerManager(bluetoothManager: self)
    
    // MARK: - Peripheral Manager
    private var peripheralManager: CBPeripheralManager!
    private var isInitialized = false
    private var dataToSend = Data()
    private var sendDataIndex: Int = 0
    
    override init() {

        // TODO: save prefered profile in user defaults
        profile = profilesViewModel.profiles.first ?? CustomBleProfile(name: "Mac OS Simulator", services: [])

        super.init()

        // Question: this runs on main thread?
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)

    }
    
    // MARK: - Public Methods
    func startAdvertising() {
        let advertisementData = CustomBleProfileConverter.convertToAdvertisementData(profile)

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
            setupServices()
            
            // Start advertising with a custom name
            peripheralManager.startAdvertising(advertisementData)
            
            isAdvertising = true
            
            addLog("Started advertising as '\(profile.name)'")
        }
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        characteristicHandlerManager.stopAllHandlers()
        addLog("Stopped advertising")
        isAdvertising = false
    }
    
    func sendData(_ data: Data, characteristic: CBMutableCharacteristic) {
        guard !connectedCentrals.isEmpty else {
            addLog("No devices connected")
            return
        }
        
        let didSend = peripheralManager.updateValue(
            data,
            for: characteristic,
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
    private func setupServices() {
        let services = CustomBleProfileConverter.convertToMutableServices(profile)

        // // Add the service to the peripheral manager
        for service in services {
            addLog("Adding service \(service.uuid.uuidString)")
            peripheralManager.add(service)
        }
        
        addLog("Service setup complete")
    }
    
    // private func updateJSHandler() {
    //     guard let settings = deviceSettings, settings.useJSFunction else {
    //         characteristicHandlerManager.removeHandler(characteristicUUID: characteristicUUID.uuidString)
    //         return
    //     }
    //     characteristicHandlerManager.updateHandler(
    //         characteristicUUID: characteristicUUID.uuidString,
    //         jsReadFunction: settings.characteristicJSReadFunction,
    //         jsWriteFunction: settings.characteristicJSWriteFunction,
    //         notifyInterval: settings.notifyInterval
    //     )
    //     addLog("Updated JavaScript handler for characteristic")
    // }
    
    // TODO: move to global logger
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
    
    // MARK: - peripheralManagerDidStartAdvertising
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
        
        // Notify the characteristic handler manager of the subscription
        characteristicHandlerManager.handleSubscription(characteristic: characteristic as! CBMutableCharacteristic)

        sendData("Welcome to MacOS Bluetooth Simulator!".data(using: .utf8)!, characteristic: characteristic as! CBMutableCharacteristic)
        
        // // Send a welcome message if not using JS functions
        // if deviceSettings?.useJSFunction != true {
        //     let welcomeData = "Welcome to MacOS Bluetooth Simulator!".data(using: .utf8)!
        //     sendData(welcomeData)
        // }
    }
    
    // MARK: - didUnsubscribeFromCharacteristic
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        addLog("Central \(central.identifier.uuidString) unsubscribed from characteristic")
        
        // Notify the characteristic handler manager of the unsubscription
        characteristicHandlerManager.handleUnsubscription(characteristicUUID: characteristic.uuid.uuidString)
        
        self.connectedCentrals.removeAll { $0.identifier == central.identifier }
    }
    
    // MARK: - didReceiveReadRequest
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        addLog("Received read request for characteristic \(request.characteristic.uuid.uuidString)")
        request.value = "Hello from Mac simulator!".data(using: .utf8)!
        peripheral.respond(to: request, withResult: .success)

        // if request.characteristic.uuid == characteristicUUID {
        //     // Check if we should use JS function for read
        //     if let settings = deviceSettings, settings.useJSFunction, 
        //        let jsResponse = characteristicHandlerManager.handleReadRequest(characteristicUUID: characteristicUUID.uuidString) {
        //         request.value = jsResponse
        //         addLog("Responded to read request with JS function result")
        //     } else {
        //         // Use auto response from settings
        //         let responseText = deviceSettings?.autoResponseText ?? "Hello from Mac simulator!"
        //         request.value = responseText.data(using: .utf8)!
        //         addLog("Responded to read request with: \(responseText)")
        //     }
            
        //     peripheral.respond(to: request, withResult: .success)
        // } else {
        //     peripheral.respond(to: request, withResult: .attributeNotFound)
        //     addLog("Read request for unknown characteristic")
        // }
    }
    
    // MARK: - didReceiveWrite
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        addLog("Received write request for characteristic \(requests.first?.characteristic.uuid.uuidString ?? "Unknown")")
        peripheral.respond(to: requests.first!, withResult: .success)

        // for request in requests {
        //     if let value = request.value, request.characteristic.uuid == characteristicUUID {
        //         let stringValue = String(data: value, encoding: .utf8) ?? "Unknown format data"
        //         addLog("Received write: \(stringValue)")
        //         if let settings = deviceSettings, settings.useJSFunction {
        //             if let jsResponse = characteristicHandlerManager.handleWriteRequest(characteristicUUID: characteristicUUID.uuidString, value: stringValue) {
        //                 sendData(jsResponse)
        //                 addLog("Responded to write with JS function result")
        //             }
        //         } else {
        //             sendData(value)
        //         }
        //     }
        // }
    }
} 
