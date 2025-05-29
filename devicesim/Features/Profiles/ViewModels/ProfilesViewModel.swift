import Foundation
import CoreBluetooth

let testProfiles = [
            CustomBleProfile(
                uuid: CBUUID(string: "5FFE0000-5000-4000-0000-000000000000"),
                name: "Test Profile",
                deviceName: "Test Device",
                services: [
                    CustomBleService(
                        uuid: CBUUID(string: "5FFE0000-5000-4000-1000-000000000000"),
                        name: "Test Service",
                        characteristics: [
                            CustomBleCharacteristic(
                                name: "Test Characteristic 1",
                                uuid: CBUUID(string: "5FFE0000-5000-4000-1000-100000000000"),
                                properties: [.read, .write, .notify],
                                value: nil
                            )
                        ]
                    ),
                    CustomBleService(
                        uuid: CBUUID(string: "5FFE0000-5000-4000-2000-000000000000"),
                        name: "Test Service 2",
                        characteristics: [
                            CustomBleCharacteristic(
                                name: "Test Characteristic 1",
                                uuid: CBUUID(string: "5FFE0000-5000-4000-2000-100000000000"),
                                properties: [.read, .write],
                                value: nil,
                                preset: UUID(uuidString: "476E5C4D-900B-4E13-B5D6-6D6A17742110")
                            ),
                            CustomBleCharacteristic(
                                name: "Test Characteristic 2",
                                uuid: CBUUID(string: "5FFE0000-5000-4000-2000-200000000000"),
                                properties: [.notify],
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
