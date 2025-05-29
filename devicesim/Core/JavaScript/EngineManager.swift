import CoreBluetooth
import Foundation

final class EngineManager {

    static func addLog(_ message: String) {
        print("EngineManager: \(message)")
    }

    // dictonary of engines
    private static var stack: [CBUUID: JavaScriptEngine] = [:]

    // TODO: move preset respository to a separate file
    private static func loadJsFunctionsCode(preset: UUID) -> String? {
        // TODO: this one crashes
        let fileManager = FileManager.default
        var documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        documentsPath = documentsPath.appendingPathComponent("JSFunctionPresets", isDirectory: true)
        
        // find preset file which starts with the preset uuid
        let presetFiles = try? fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
        let presetFile = presetFiles?.first { $0.lastPathComponent.starts(with: preset.uuidString) }

        guard let url = presetFile else { return "" }
        guard let data = try? Data(contentsOf: url),
            let preset = try? JSONDecoder().decode(JSPreset.self, from: data)
        else { return nil }

        return preset.code
    }

    static func createEngine(preset: UUID) -> JavaScriptEngine? {
        let jsFunctionsCode = loadJsFunctionsCode(preset: preset)
        guard let jsFunctionsCode = jsFunctionsCode else { return nil }
        return JavaScriptEngine(jsFunctionsCode: jsFunctionsCode)
    }

    private static func register(characteristic: CBUUID, preset: UUID, shared: CBUUID?) {
        if shared != nil {
            // TODO: proper error handling
            stack[characteristic] = stack[shared!]!
        } else {
            let engine = createEngine(preset: preset)
            stack[characteristic] = engine
        }
    }

        // Question: does this cause a memory leak?
    // destroy all engines in the stack
    static func destroyStack() {
        stack.removeAll()
    }

    static func createStack(profile: CustomBleProfile) {

        // clean up stack
        destroyStack()

        let characteristics: [CustomBleCharacteristic] = profile.services.flatMap {
            $0.characteristics
        }

        // sort characteristics by shared, this is important because shared characteristics need to be registered first
        let sortedCharacteristics = characteristics.sorted { $0.shared != nil && $1.shared == nil }

        for characteristic in sortedCharacteristics {
            if let preset = characteristic.preset {
                register(
                    characteristic: characteristic.uuid, preset: preset,
                    shared: characteristic.shared)
            } else {
                // TODO: proper error handling
                addLog(
                    "characteristic \(characteristic.uuid) has no preset, skipping attaching a handler (js engine)"
                )
            }
        }
    }

    static func route(characteristic: CBUUID, action: CBCharacteristicProperties, data: Data?) -> String
    {
        if let engine = stack[characteristic] {
            switch action {
            case .read:
                return engine.runRead()
            case .write:
                addLog("write is currently not supported")
            case .writeWithoutResponse:
                addLog("write without response is currently not supported")
            case .notify:
                addLog("notify is currently not supported")
            case .indicate:
                addLog("indicate is currently not supported")
            default:
                addLog("characteristic \(characteristic) has no action \(action)")
            }
        } else {
            // TODO: proper error handling
            addLog("No engine found for characteristic \(characteristic)")
        }
        return "No Execution" 
    }
}
