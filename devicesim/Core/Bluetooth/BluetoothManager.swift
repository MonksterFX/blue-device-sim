import Foundation
import CoreBluetooth
import Combine
import AppKit

class BluetoothManager: NSObject, ObservableObject {
    private var profilesViewModel: ProfilesViewModel = ProfilesViewModel()
    private var logger = LogManager.shared.logger(for: .ble)
    
    // MARK: - Published Properties
    @Published var isAdvertising = false
    @Published var connectedCentrals: [CBCentral] = []
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var stateMessage: String = "Initializing Bluetooth..."
    @Published var logs: [LogStoreMessage] = []

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
        logs = logger.logStore.logs

    }
    
    // MARK: - Public Methods
    func startAdvertising() {
        let advertisementData = CustomBleProfileConverter.convertToAdvertisementData(profile)

        guard peripheralManager.state == .poweredOn else {
            let errorMessage = "Cannot start advertising - Bluetooth is not powered on (Current state: \(stateDescription(for: peripheralManager.state)))"
            logger.error(errorMessage)
            
            // Provide more helpful diagnostics
            if peripheralManager.state == .unauthorized {
                logger.error("Bluetooth permission denied. Please check System Settings > Privacy & Security > Bluetooth")
            } else if peripheralManager.state == .poweredOff {
                logger.error("Bluetooth is turned off. Please turn on Bluetooth in System Settings or Control Center")
            }
            
            return
        }
        
        if !peripheralManager.isAdvertising {
            setupServices()
            
            // Start advertising with a custom name
            peripheralManager.startAdvertising(advertisementData)
            
            isAdvertising = true
            
            logger.info("Started advertising as '\(profile.name)'")
        }
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        characteristicHandlerManager.stopAllHandlers()
        logger.info("Stopped advertising")
        isAdvertising = false
    }
    
    func sendData(_ data: Data, characteristic: CBMutableCharacteristic) {
        guard !connectedCentrals.isEmpty else {
            logger.error("No devices connected")
            return
        }
        
        let didSend = peripheralManager.updateValue(
            data,
            for: characteristic,
            onSubscribedCentrals: nil
        )
        
        if didSend {
            logger.info("Sent data: \(String(data: data, encoding: .utf8) ?? "Unknown")")
        } else {
            logger.error("Failed to send data")
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
            logger.info("Adding service \(service.uuid.uuidString)")
            peripheralManager.add(service)
        }
        
        EngineManager.createStack(profile: profile)

        logger.info("Service setup complete")
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
            self.logger.info(message)
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
            logger.info("Bluetooth is powered on")
        case .poweredOff:
            stateMessage = "Bluetooth is powered off - Please turn on Bluetooth"
            logger.info("Bluetooth is powered off")
            isAdvertising = false
        case .resetting:
            stateMessage = "Bluetooth is resetting"
            logger.info("Bluetooth is resetting")
        case .unauthorized:
            stateMessage = "Bluetooth permission denied - Check System Settings"
            logger.error("Bluetooth is unauthorized - Check System Settings > Privacy & Security > Bluetooth")
        case .unsupported:
            stateMessage = "Bluetooth is not supported on this device"
            logger.error("Bluetooth is not supported")
        case .unknown:
            stateMessage = "Bluetooth state is unknown"
            logger.error("Bluetooth state is unknown")
        @unknown default:
            stateMessage = "Unknown Bluetooth state"
            logger.error("Unknown Bluetooth state")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            logger.error("Error adding service: \(error.localizedDescription)")
        } else {
            logger.info("Service added successfully")
        }
    }
    
    // MARK: - peripheralManagerDidStartAdvertising
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            logger.error("Error advertising: \(error.localizedDescription)")
            isAdvertising = false
        } else {
            logger.info("Advertising started successfully")
            isAdvertising = true
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didConnect central: CBCentral) {
        logger.info("Connected to central \(central.identifier.uuidString)")
        self.connectedCentrals.append(central)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didDisconnect central: CBCentral, error: Error?) {
        logger.info("Disconnected from central \(central.identifier.uuidString)")
        self.connectedCentrals.removeAll { $0.identifier == central.identifier }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        logger.info("Central \(central.identifier.uuidString) subscribed to characteristic")
        
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
        logger.info("Central \(central.identifier.uuidString) unsubscribed from characteristic")
        
        // Notify the characteristic handler manager of the unsubscription
        characteristicHandlerManager.handleUnsubscription(characteristicUUID: characteristic.uuid.uuidString)
        
        self.connectedCentrals.removeAll { $0.identifier == central.identifier }
    }
    
    // MARK: - didReceiveReadRequest
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        logger.info("Received read request for characteristic \(request.characteristic.uuid.uuidString)")
        
        let value = EngineManager.route(characteristic: request.characteristic.uuid, action: .read, data: nil)
    
        request.value = value ?? Data()
        peripheral.respond(to: request, withResult: .success)
    }
    
    // MARK: - didReceiveWrite
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        logger.info("Received write request for characteristic \(requests.first?.characteristic.uuid.uuidString ?? "Unknown")")
        
        EngineManager.route(characteristic: requests.first!.characteristic.uuid, action: requests.first!.characteristic.properties, data: requests.first!.value!)

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
