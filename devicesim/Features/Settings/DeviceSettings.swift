import Foundation

struct DeviceSettingsData: Codable {
    var deviceName: String
    var serviceUUID: String
    var characteristicUUID: String
    var autoResponse: Bool
    var autoResponseText: String
    var savedMessages: [String]
    var characteristicJSReadFunction: String
    var characteristicJSWriteFunction: String
    var useJSFunction: Bool
    var notifyInterval: Double
    let createdAt: Date
    
    init(deviceName: String, serviceUUID: String, characteristicUUID: String, 
         autoResponse: Bool, autoResponseText: String, savedMessages: [String],
         characteristicJSReadFunction: String = "", characteristicJSWriteFunction: String = "", useJSFunction: Bool = false,
         notifyInterval: Double = 1.0) {
        self.deviceName = deviceName
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
        self.autoResponse = autoResponse
        self.autoResponseText = autoResponseText
        self.savedMessages = savedMessages
        self.characteristicJSReadFunction = characteristicJSReadFunction
        self.characteristicJSWriteFunction = characteristicJSWriteFunction
        self.useJSFunction = useJSFunction
        self.notifyInterval = notifyInterval
        self.createdAt = Date()
    }
}

class DeviceSettings: ObservableObject {
    @Published var deviceName: String = "MacOS Simulator"
    @Published var serviceUUID: String = "5FFE0000-5000-4000-3000-200000000000"
    @Published var characteristicUUID: String = "5FFE0001-5000-4000-3000-200000000000"
    @Published var autoResponse: Bool = true
    @Published var autoResponseText: String = "Hello from MacOS Simulator!"
    @Published var currentProfileName: String = "default"
    
    // New JavaScript function properties
    @Published var characteristicJSReadFunction: String = "// JS read function\nreturn 'Read value: ' + new Date().toISOString();"
    @Published var characteristicJSWriteFunction: String = "// JS write function\nconsole.log('Write value:', value); return true;"
    // Deprecated, for migration only
    @Published var characteristicJSFunction: String = ""
    
    // Saved message templates for quick sending
    @Published var savedMessages: [String] = [
        "Hello!",
        "Test message",
        "Status: OK",
        "Battery: 100%"
    ]
    
    // Add this property for notifyInterval
    @Published var notifyInterval: Double = 1.0
    // Add this property for useJSFunction
    @Published var useJSFunction: Bool = false
    
    private let fileManager = FileManager.default
    private var settingsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("DeviceSim", isDirectory: true)
    }
    
    init() {
        createSettingsDirectoryIfNeeded()
        loadSettings(profile: "default")
    }
    
    private func createSettingsDirectoryIfNeeded() {
        do {
            if !fileManager.fileExists(atPath: settingsDirectory.path) {
                try fileManager.createDirectory(at: settingsDirectory, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating settings directory: \(error.localizedDescription)")
        }
    }
    
    private func getSettingsFileURL(for profile: String) -> URL {
        return settingsDirectory.appendingPathComponent("\(profile).json")
    }
    
    func addSavedMessage(_ message: String) {
        guard !message.isEmpty, !savedMessages.contains(message) else { return }
        savedMessages.append(message)
        saveSettings(as: currentProfileName)
    }
    
    func removeSavedMessage(at index: Int) {
        guard savedMessages.indices.contains(index) else { return }
        savedMessages.remove(at: index)
        saveSettings(as: currentProfileName)
    }
    
    func saveSettings(as profile: String) {
        let settings = DeviceSettingsData(
            deviceName: deviceName,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            autoResponse: autoResponse,
            autoResponseText: autoResponseText,
            savedMessages: savedMessages,
            characteristicJSReadFunction: characteristicJSReadFunction,
            characteristicJSWriteFunction: characteristicJSWriteFunction,
            useJSFunction: useJSFunction,
            notifyInterval: notifyInterval
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(settings)
            try data.write(to: getSettingsFileURL(for: profile))
            currentProfileName = profile
        } catch {
            print("Error saving settings profile '\(profile)': \(error.localizedDescription)")
        }
    }
    
    func loadSettings(profile: String) {
        let fileURL = getSettingsFileURL(for: profile)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            if profile == "default" {
                // If default profile doesn't exist, create it
                saveSettings(as: "default")
            }
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let settings = try decoder.decode(DeviceSettingsData.self, from: data)
            deviceName = settings.deviceName
            serviceUUID = settings.serviceUUID
            characteristicUUID = settings.characteristicUUID
            autoResponse = settings.autoResponse
            autoResponseText = settings.autoResponseText
            savedMessages = settings.savedMessages
            useJSFunction = settings.useJSFunction
            notifyInterval = settings.notifyInterval
            // Migration logic for JS functions
            if !settings.characteristicJSReadFunction.isEmpty || !settings.characteristicJSWriteFunction.isEmpty {
                characteristicJSReadFunction = settings.characteristicJSReadFunction
                characteristicJSWriteFunction = settings.characteristicJSWriteFunction
            } else if let legacyJS = (dataToLegacyJSFunction(data: data)) {
                characteristicJSReadFunction = legacyJS
                characteristicJSWriteFunction = legacyJS
            } else {
                characteristicJSReadFunction = "// JS read function\nreturn 'Read value: ' + new Date().toISOString();"
                characteristicJSWriteFunction = "// JS write function\nconsole.log('Write value:', value); return true;"
            }
            currentProfileName = profile
        } catch {
            print("Error loading settings profile '\(profile)': \(error.localizedDescription)")
        }
    }
    
    /// Helper to extract legacy characteristicJSFunction from raw data if present
    private func dataToLegacyJSFunction(data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let legacy = json["characteristicJSFunction"] as? String, !legacy.isEmpty {
            return legacy
        }
        return nil
    }
    
    func listProfiles() -> [(name: String, createdAt: Date)] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: settingsDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles)
            
            return fileURLs.compactMap { url -> (name: String, createdAt: Date)? in
                guard url.pathExtension == "json" else { return nil }
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let settings = try decoder.decode(DeviceSettingsData.self, from: data)
                    let profileName = url.deletingPathExtension().lastPathComponent
                    return (profileName, settings.createdAt)
                } catch {
                    return nil
                }
            }.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("Error listing profiles: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteProfile(_ profile: String) -> Bool {
        guard profile != "default" else {
            print("Cannot delete default profile")
            return false
        }
        
        let fileURL = getSettingsFileURL(for: profile)
        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            print("Error deleting profile '\(profile)': \(error.localizedDescription)")
            return false
        }
    }
    
    func resetToDefaults() {
        deviceName = "MacOS Simulator"
        serviceUUID = "5FFE0000-5000-4000-3000-200000000000"
        characteristicUUID = "5FFE0001-5000-4000-3000-200000000000"
        autoResponse = true
        autoResponseText = "Hello from MacOS Simulator!"
        characteristicJSReadFunction = "// JS read function\nreturn 'Read value: ' + new Date().toISOString();"
        characteristicJSWriteFunction = "// JS write function\nconsole.log('Write value:', value); return true;"
        useJSFunction = false
        notifyInterval = 1.0
        savedMessages = [
            "Hello!",
            "Test message",
            "Status: OK",
            "Battery: 100%"
        ]
        saveSettings(as: currentProfileName)
    }
} 