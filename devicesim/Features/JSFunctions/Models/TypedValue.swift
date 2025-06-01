import Foundation

@Observable
class TypedValue: Identifiable {
    let id = UUID()
    let type: DataType
    let stringLength: Int?
    var value: String = ""

    init(type: DataType, stringLength: Int?, value: String = "") {
        self.type = type
        self.stringLength = stringLength
        self.value = value
    }
}