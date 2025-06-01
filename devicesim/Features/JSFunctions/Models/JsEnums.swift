enum ConvertionTypes: String, CaseIterable {
    case string = "String"
    case number = "Number"
    case buffer = "Buffer"
}

enum OperationType: String, CaseIterable, Identifiable {
    case read = "Read"
    case write = "Write"
    case notify = "Notify"
    var id: String { rawValue }
}

enum TypeHintKey: String {
    case readIn = "readTypes.in"
    case readOut = "readTypes.out"
    case writeIn = "writeTypes.in"
    case writeOut = "writeTypes.out"
}

enum DataType: String {
    case uint8 = "uint8"
    case int8 = "int8"
    case uint16 = "uint16"
    case int16 = "int16"
    case uint32 = "uint32"
    case int32 = "int32"
    case float = "float"
    case double = "double"
    case string = "string"
    case fixedString = "fixedString"
    case unkown = "buffer"
}
