import Foundation
import Combine
import SwiftUI

class ContentViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    func setupSettingsObservers(deviceSettings: DeviceSettings, bluetoothManager: BluetoothManager) {
        // When JS settings change, and we're advertising, update the handlers
        let jsSettingsPublisher = deviceSettings.$useJSFunction
            .combineLatest(
                deviceSettings.$characteristicJSFunction,
                deviceSettings.$notifyInterval
            )
        
        jsSettingsPublisher
            // Debounce to avoid rapid restarts if multiple settings change quickly
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak deviceSettings, weak bluetoothManager] _, _, _ in
                guard let settings = deviceSettings, let manager = bluetoothManager else { return }
                
                // If we're currently advertising, save settings and restart advertising to apply changes
                if manager.isAdvertising {
                    print("Settings changed while advertising. Restarting advertising...")
                    settings.saveSettings(as: settings.currentProfileName)
                    
                    // Dispatch restart slightly later to ensure settings are saved
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        manager.stopAdvertising()
                        // Give a moment for stop to complete before starting again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                             manager.startAdvertising()
                        }
                    }
                }
            }
            .store(in: &cancellables) // Storing in the ViewModel's set is fine
    }
} 