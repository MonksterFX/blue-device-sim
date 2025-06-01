import Foundation
import JavaScriptCore

extension JSValue {
    func toUInt8ArrayData() -> Data? {
        guard let length = forProperty("length")?.toInt32(), length > 0 else { return nil }

        var bytes = [UInt8]()
        for i in 0..<length {
            if let byte = atIndex(Int(i))?.toInt32() {
                bytes.append(UInt8(byte))
            }
        }
        return Data(bytes)
    }
    
    static func toUint8Array(_ data: Data, in context: JSContext) -> JSValue? {
        // Create a new Uint8Array of the same length in JS
        guard let uint8ArrayConstructor = context.objectForKeyedSubscript("Uint8Array"),
              let jsArray = uint8ArrayConstructor.construct(withArguments: [data.count]) else {
            print("Failed to create Uint8Array in JS")
            return nil
        }

        // Copy Swift Data into JS Uint8Array
        for (index, byte) in data.enumerated() {
            jsArray.setValue(Int(byte), at: index)
        }

        return jsArray
    }
}
