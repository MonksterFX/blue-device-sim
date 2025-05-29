import CoreBluetooth

struct CustomBleProfileConverter {

    static func convertToAdvertisementData(_ profile: CustomBleProfile) -> [String: Any] {
        var advertisementData: [String: Any] = [:]
        
        // Add local name if specified
       advertisementData[CBAdvertisementDataLocalNameKey] = profile.name

        // Add primary service UUID if defined -> 2+16bytes
        if let primaryService = profile.services.first {
            advertisementData[CBAdvertisementDataServiceUUIDsKey] = [primaryService.uuid]
        }

        // Set whether device is connectable
        advertisementData[CBAdvertisementDataIsConnectable] = NSNumber(value: true)
        
        return advertisementData
    }
    
    static func convertToMutableServices(_ profile: CustomBleProfile) -> [CBMutableService] {
        return profile.services.map { service in
            // Create characteristics for the service
            let characteristics = service.characteristics.map { characteristic in
                CBMutableCharacteristic(
                    type: characteristic.uuid,
                    properties: characteristic.properties,
                    value: characteristic.value,
                    permissions: permissionsFromProperties(characteristic.properties)
                )
            }
            
            // Create the service
            let mutableService = CBMutableService(
                type: service.uuid,
                // TODO: check if secondary service needs to be supported
                primary: true
            )
            
            // Add characteristics to service
            mutableService.characteristics = characteristics
            
            return mutableService
        }
    }
    
    private static func permissionsFromProperties(_ properties: CBCharacteristicProperties) -> CBAttributePermissions {
        var permissions: CBAttributePermissions = []
        
        if properties.contains(.read) {
            permissions.insert(.readable)
        }
        
        if properties.contains(.write) || properties.contains(.writeWithoutResponse) {
            permissions.insert(.writeable)
        }
        
        return permissions
    }
}
