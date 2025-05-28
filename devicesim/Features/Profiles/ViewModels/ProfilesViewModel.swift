import Foundation
import CoreBluetooth

let testProfiles = [
            CustomBleProfile(
                uuid: CBUUID(string: "5FFE0000-5000-4000-3000-200000000000"),
                name: "Test Profile",
                deviceName: "Test Device",
                services: [
                    CustomBleService(
                        uuid: CBUUID(string: "1800"),
                        name: "Test Service",
                        characteristics: [
                            CustomBleCharacteristic(
                                name: "Test Characteristic 1",
                                uuid: CBUUID(string: "2A00"),
                                properties: [.read, .write, .notify],
                                value: nil
                            )
                        ]
                    ),
                    CustomBleService(
                        uuid: CBUUID(string: "1801"),
                        name: "Test Service 2",
                        characteristics: [
                            CustomBleCharacteristic(
                                name: "Test Characteristic 1",
                                uuid: CBUUID(string: "2A01"),
                                properties: [.read, .write, .notify],
                                value: nil
                            ),
                            CustomBleCharacteristic(
                                name: "Test Characteristic 2",
                                uuid: CBUUID(string: "2A02"),
                                properties: [.read, .write, .notify],
                                value: nil
                            ),
                        ]
                    ),
                ]
            )
        ]

@Observable
final class ProfilesViewModel {
    private(set) var profiles: [CustomBleProfile]
    var selectedProfile: CustomBleProfile? = nil

    init() {
        // Load profiles from disk
        self.profiles = testProfiles
    }

    func selectProfile(profile: CustomBleProfile) {
        self.selectedProfile = profile
    }
}
