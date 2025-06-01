import Foundation

class TypeHintParser {
    static func parse(_ input: String) -> [TypedValue] {
        // Split the input string by commas and trim whitespace
        let components = input.components(separatedBy: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        return components.compactMap { typeString in
            // Check if it's a String with length specification
            if typeString.lowercased().hasPrefix("string(") && typeString.hasSuffix(")") {
                let lengthStr = typeString.dropFirst(7).dropLast(1)
                if let length = Int(lengthStr) {
                    return TypedValue(type: .string, stringLength: length)
                }
            }

            // Handle regular types
            if let dataType = DataType(rawValue: typeString.lowercased()) {
                return TypedValue(type: dataType, stringLength: nil)
            }

            return nil
        }
    }
}
