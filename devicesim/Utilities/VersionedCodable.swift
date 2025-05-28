import Foundation

protocol VersionedCodable: Codable {
    var version: String { get }
}

struct VersionedEncoder {
    static func encode<T: VersionedCodable>(_ value: T, using encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(value)
    }
    
    static func decode<T: VersionedCodable>(_ type: T.Type, from data: Data, using decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let decoded = try decoder.decode(type, from: data)
        return decoded
    }
}
