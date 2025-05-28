import CoreBluetooth
import Foundation

// MARK: - UUID Wrapper
struct CBUUIDWrapper: Codable {
    let uuid: CBUUID

    init(_ uuid: CBUUID) {
        self.uuid = uuid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let uuidString = try container.decode(String.self)
        self.uuid = CBUUID(string: uuidString)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(uuid.uuidString)
    }
}

struct CustomBleProfile: VersionedCodable, Hashable {
    // version is used to track changes to the profile model
    var version: String = "1.0.0"

    var uuid: CBUUID
    var name: String = ""
    var deviceName: String = ""
    var services: [CustomBleService] = []
    var manufacturerData: Data?
    var rssi: Int?
    var isConnected: Bool = false

    enum CodingKeys: String, CodingKey {
        case uuid, name, deviceName, services, manufacturerData, rssi, isConnected, version
    }

    init(
        uuid: CBUUID = CBUUID(),
        name: String = "",
        deviceName: String = "",
        services: [CustomBleService] = [],
        manufacturerData: Data? = nil,
        rssi: Int? = nil,
        isConnected: Bool = false
    ) {
        self.uuid = uuid
        self.name = name
        self.deviceName = deviceName
        self.services = services
        self.manufacturerData = manufacturerData
        self.rssi = rssi
        self.isConnected = isConnected
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uuidWrapper = try container.decode(CBUUIDWrapper.self, forKey: .uuid)
        uuid = uuidWrapper.uuid
        name = try container.decode(String.self, forKey: .name)
        deviceName = try container.decode(String.self, forKey: .deviceName)
        services = try container.decode([CustomBleService].self, forKey: .services)
        manufacturerData = try container.decodeIfPresent(Data.self, forKey: .manufacturerData)
        rssi = try container.decodeIfPresent(Int.self, forKey: .rssi)
        isConnected = try container.decode(Bool.self, forKey: .isConnected)
        version = try container.decode(String.self, forKey: .version)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(CBUUIDWrapper(uuid), forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(deviceName, forKey: .deviceName)
        try container.encode(services, forKey: .services)
        try container.encodeIfPresent(manufacturerData, forKey: .manufacturerData)
        try container.encodeIfPresent(rssi, forKey: .rssi)
        try container.encode(isConnected, forKey: .isConnected)
        try container.encode(version, forKey: .version)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    static func == (lhs: CustomBleProfile, rhs: CustomBleProfile) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

struct CustomBleService: Codable {
    var uuid: CBUUID
    var name: String = ""
    var isPrimary: Bool = true
    var characteristics: [CustomBleCharacteristic] = []

    init(
        uuid: CBUUID = CBUUID(),
        name: String = "",
        isPrimary: Bool = true,
        characteristics: [CustomBleCharacteristic] = []
    ) {
        self.uuid = uuid
        self.name = name
        self.isPrimary = isPrimary
        self.characteristics = characteristics
    }

    enum CodingKeys: String, CodingKey {
        case uuid, name, isPrimary, characteristics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uuidWrapper = try container.decode(CBUUIDWrapper.self, forKey: .uuid)
        uuid = uuidWrapper.uuid
        name = try container.decode(String.self, forKey: .name)
        isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        characteristics = try container.decode(
            [CustomBleCharacteristic].self, forKey: .characteristics)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(CBUUIDWrapper(uuid), forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(isPrimary, forKey: .isPrimary)
        try container.encode(characteristics, forKey: .characteristics)
    }
}

struct CustomBleCharacteristic: Codable {
    var name: String = ""
    var uuid: CBUUID
    var properties: CBCharacteristicProperties
    var value: Data?
    var isNotifying: Bool = false
    // var descriptors: [CustomBleDescriptor] = []

    init(
        name: String = "",
        uuid: CBUUID = CBUUID(),
        properties: CBCharacteristicProperties,
        value: Data? = nil,
        isNotifying: Bool = false
    ) {
        self.name = name
        self.uuid = uuid
        self.properties = properties
        self.value = value
        self.isNotifying = isNotifying
    }

    enum CodingKeys: String, CodingKey {
        case uuid, name, properties, value, isNotifying, descriptors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uuidWrapper = try container.decode(CBUUIDWrapper.self, forKey: .uuid)
        uuid = uuidWrapper.uuid
        name = try container.decode(String.self, forKey: .name)
        let propertiesRawValue = try container.decode(UInt.self, forKey: .properties)
        properties = CBCharacteristicProperties(rawValue: propertiesRawValue)
        value = try container.decodeIfPresent(Data.self, forKey: .value)
        isNotifying = try container.decode(Bool.self, forKey: .isNotifying)
        // descriptors = try container.decode([CustomBleDescriptor].self, forKey: .descriptors)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(CBUUIDWrapper(uuid), forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(properties.rawValue, forKey: .properties)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encode(isNotifying, forKey: .isNotifying)
        // try container.encode(descriptors, forKey: .descriptors)
    }
}

// MARK: - CBCharacteristicProperties Codable Conformance
extension CBCharacteristicProperties: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(UInt.self)
        self.init(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
