import Foundation

/// Manages app-wide configuration and feature flags
enum AppConfig {
    // MARK: - App Information
    enum Info {
        static let appName = "DeviceSim"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.devicesim"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Feature Flags
    enum Features {
        static let isDebugMode = false
        static let enableAdvancedSettings = true
        static let enableBetaFeatures = false
        static let enableDetailedLogging = false
    }
    
    // MARK: - Bluetooth Configuration
    enum Bluetooth {
        static let scanTimeout: TimeInterval = 10
        static let connectionTimeout: TimeInterval = 5
        static let autoReconnectAttempts = 3
        static let minimumRSSI: Int = -70
    }
    
    // MARK: - Network Configuration
    enum Network {
        static let baseURL = URL(string: "https://api.devicesim.com")!
        static let timeoutInterval: TimeInterval = 30
        static let retryAttempts = 3
    }
    
    // MARK: - Storage Keys
    enum StorageKeys {
        static let userPreferences = "user_preferences"
        static let deviceSettings = "device_settings"
        static let lastConnectedDevices = "last_connected_devices"
    }
}

// MARK: - Environment
extension AppConfig {
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            // You can customize this based on your build configuration
            return .production
            #endif
        }
    }
} 