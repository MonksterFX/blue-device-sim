import Foundation

struct TypeConverter {
    static func convertToString(data: Data, to type: DataType) -> String {
        switch type {
        case .string:
            return String(data: data, encoding: .utf8)!
        case .fixedString:
            return String(data: data, encoding: .utf8)!
        case .uint8:
            guard data.count >= MemoryLayout<UInt8>.size else { return "<invalid data>" }
            let value = data.withUnsafeBytes { $0.load(as: UInt8.self) }
            return String(value)
        case .int8:
            guard data.count >= MemoryLayout<Int8>.size else { return "<invalid data>" }
            let value = data.withUnsafeBytes { $0.load(as: Int8.self) }
            return String(value)
        case .uint16:
            guard data.count >= MemoryLayout<UInt16>.size else { return "<invalid data>" }
            let value = data.withUnsafeBytes { $0.load(as: UInt16.self) }
            return String(value)
        case .int16:
            guard data.count >= MemoryLayout<Int16>.size else { return "<invalid data>" }
            let value = data.withUnsafeBytes { $0.load(as: Int16.self) }
            return String(value)
        case .uint32:
            guard data.count >= MemoryLayout<UInt32>.size else { return "<invalid data>" }
            let value = data.withUnsafeBytes { $0.load(as: UInt32.self) }
            return String(value)
        case .int32:
            guard data.count >= MemoryLayout<Int32>.size else { return "<invalid data>" }
            let value = data.withUnsafeBytes { $0.load(as: Int32.self) }
            return String(value)
        case .float:
            guard data.count >= MemoryLayout<Float>.size else { return "<invalid data>" }
            let value = data.withUnsafeBytes { $0.load(as: Float.self) }
            return String(value)
        case .double:
            guard data.count >= MemoryLayout<Double>.size else { return "<invalid data>" }
            let value = data.withUnsafeBytes { $0.load(as: Double.self) }
            return String(value)
        case .unkown:
            return data.map { String(format: "%02X", $0) }.joined(separator: " ")
        }
    }

    static func convertFromString(value: String, to type: DataType) -> Data {
        switch type {
        case .string:
            return value.data(using: .utf8)!
        case .fixedString:
            return value.data(using: .utf8)!
        case .uint8:
            return withUnsafeBytes(of: UInt8(value)!) { Data($0) }
        case .int8:
            return withUnsafeBytes(of: Int8(value)!) { Data($0) }
        case .uint16:
            return withUnsafeBytes(of: UInt16(value)!) { Data($0) }
        case .int16:
            return withUnsafeBytes(of: Int16(value)!) { Data($0) }
        case .uint32:
            return withUnsafeBytes(of: UInt32(value)!) { Data($0) }
        case .int32:
            return withUnsafeBytes(of: Int32(value)!) { Data($0) }
        case .float:
            return withUnsafeBytes(of: Float(value)!) { Data($0) }
        case .double:
            return withUnsafeBytes(of: Double(value)!) { Data($0) }
        case .unkown:
            return dataFromHexString(value) ?? Data()
        }
    }

    static func dataFromHexString(_ hex: String) -> Data? {
        var data = Data()
        var hex = hex

        // Remove any whitespace or prefix (e.g. "0x")
        hex = hex.replacingOccurrences(of: " ", with: "")
        hex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex

        guard hex.count % 2 == 0 else { return nil }  // Must be even-length

        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                return nil  // Invalid hex digit
            }
            index = nextIndex
        }
        return data
    }
}
