import CryptoKit
//
//  JSFunctionsAdminViewModel.swift
//  devicesim
//
//  Created by Max Mönch on 26.04.25.
//
import Foundation

enum ConvertionTypes {
    case string
    case number
    case buffer
}

func convertToString(data: Data, to type: ConvertionTypes) -> String {
    switch type {
    case .string:
        return String(data: data, encoding: .utf8)!
    case .number:
        return String(
            data.withUnsafeBytes {
                $0.load(as: Double.self)
            })
    case .buffer:
            return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

func convertFromString(value: String, to type: ConvertionTypes) -> Data {
    switch type {
    case .string:
        return value.data(using: .utf8)!
    case .number:
        var double = Double(value)
        return withUnsafeBytes(of: &double) { Data($0) } ?? Data()
    case .buffer:
        return dataFromHexString(value) ?? Data()
    }
}

func dataFromHexString(_ hex: String) -> Data? {
    var data = Data()
    var hex = hex

    // Remove any whitespace or prefix (e.g. "0x")
    hex = hex.replacingOccurrences(of: " ", with: "")
    hex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex

    guard hex.count % 2 == 0 else { return nil } // Must be even-length

    var index = hex.startIndex
    while index < hex.endIndex {
        let nextIndex = hex.index(index, offsetBy: 2)
        let byteString = hex[index..<nextIndex]
        if let byte = UInt8(byteString, radix: 16) {
            data.append(byte)
        } else {
            return nil // Invalid hex digit
        }
        index = nextIndex
    }

    return data
}

@Observable
class JSFunctionsAdminViewModel {
    let logger = LogManager.shared.logger(for: .jsEngine)
    
    var presets: [JSPreset] = []
    var selectedPreset: JSPreset? = nil
    var jsCode: String = ""
    var operation: OperationType = .read
    var testInput: String = ""
    var lastResult: String = ""

    var isRenaming: Bool = false
    var renameText: String = ""
    var presetToDelete: JSPreset? = nil
    var title: String = ""
    var description: String = ""
    var showInvalidNameAlert: Bool = false
    var showNewPresetAlert: Bool = false
    var newPresetName: String = ""

    // js engine context
    var context: JavaScriptEngine? = nil
    var inputType: ConvertionTypes = .string
    var resultType: ConvertionTypes = .string

    // change detection
    var initialCodeHash: String = ""
    var hasUnsavedChanges: Bool = false
    var showUnsavedChangesAlert: Bool = false
    var pendingPreset: JSPreset? = nil

    private let fileManager = FileManager.default
    private var presetsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("JSFunctionPresets", isDirectory: true)
    }

    enum OperationType: String, CaseIterable, Identifiable {
        case read = "Read"
        case write = "Write"
        case notify = "Notify"
        var id: String { rawValue }
    }

    init() {
        logger.debug("Presets directory: \(presetsDirectory.path)")
        loadPresetsFromDisk()
    }

    func loadPresetsFromDisk() {
        do {
            if !fileManager.fileExists(atPath: presetsDirectory.path) {
                try fileManager.createDirectory(
                    at: presetsDirectory, withIntermediateDirectories: true)
            }
            let files = try fileManager.contentsOfDirectory(
                at: presetsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = files.filter { $0.pathExtension == "json" }
            let loadedPresets: [JSPreset] = jsonFiles.compactMap { url in
                guard let data = try? Data(contentsOf: url),
                    let preset = try? JSONDecoder().decode(JSPreset.self, from: data)
                else { return nil }
                return preset
            }
            presets = loadedPresets
            if let first = presets.first {
                DispatchQueue.main.async { [weak self] in
                    self?.selectPreset(first)
                }
            }
        } catch {
            logger.error("Failed to load presets: \(error.localizedDescription)")
        }
    }

    func selectPreset(_ preset: JSPreset) {
        if hasUnsavedChanges {
            pendingPreset = preset
            showUnsavedChangesAlert = true
            return
        }

        selectedPreset = preset
        loadPreset(preset: preset)
    }

    private func loadPreset(preset: JSPreset) {
        let fileURL = presetsDirectory.appendingPathComponent(createPresetFileName(preset: preset))
        if let data = try? Data(contentsOf: fileURL),
            let loaded = try? JSONDecoder().decode(JSPreset.self, from: data)
        {
            jsCode = loaded.code
            description = loaded.description
        } else {
            jsCode = ""
            description = ""
        }
        initialCodeHash = HashUtils.sha256(jsCode)
        hasUnsavedChanges = false
        pendingPreset = nil
    }

    func saveCurrentPreset() {
        guard let preset = selectedPreset else { return }
        guard isValidPresetName(preset.name) else {
            showInvalidNameAlert = true
            return
        }
        let updatedPreset = JSPreset(
            id: preset.id, name: preset.name, code: jsCode, description: description)
        do {
            if !fileManager.fileExists(atPath: presetsDirectory.path) {
                try fileManager.createDirectory(
                    at: presetsDirectory, withIntermediateDirectories: true)
            }
            let fileURL = presetsDirectory.appendingPathComponent(
                createPresetFileName(preset: preset))
            let data = try JSONEncoder().encode(updatedPreset)
            try data.write(to: fileURL)
            logger.info("Saved preset '\(preset.name)' to disk.")
            hasUnsavedChanges = false
            DispatchQueue.main.async { [weak self] in
                self?.loadPresetsFromDisk()
            }
        } catch {
            logger.error("Failed to save preset: \(error.localizedDescription)")
        }
    }

    func discardChanges() {
        if let preset = pendingPreset {
            selectedPreset = preset
            let fileURL = presetsDirectory.appendingPathComponent(
                createPresetFileName(preset: preset))
            if let data = try? Data(contentsOf: fileURL),
                let loaded = try? JSONDecoder().decode(JSPreset.self, from: data)
            {
                jsCode = loaded.code
                description = loaded.description
            } else {
                jsCode = ""
                description = ""
            }
            hasUnsavedChanges = false
            pendingPreset = nil
        }
    }

    func saveChanges() {
        saveCurrentPreset()
        if let preset = pendingPreset {
            selectPreset(preset)
        }
    }

    // Add observers for jsCode and description changes
    func changeDetection() {
        let codeHash = HashUtils.sha256(jsCode)
        if codeHash != initialCodeHash {
            hasUnsavedChanges = true
        }
    }

    func renamePreset(_ newName: String) {
        guard let oldPreset = selectedPreset, !newName.isEmpty, oldPreset.name != newName else {
            return
        }
        guard isValidPresetName(newName) else {
            showInvalidNameAlert = true
            return
        }
        // TODO: find by uuid
        let oldURL = presetsDirectory.appendingPathComponent("\(oldPreset.name).json")
        let newURL = presetsDirectory.appendingPathComponent("\(newName).json")
        do {
            if fileManager.fileExists(atPath: newURL.path) {
                logger.error("A preset with that name already exists.")
                return
            }
            try fileManager.moveItem(at: oldURL, to: newURL)
            let renamedPreset = JSPreset(
                id: oldPreset.id, name: newName, code: jsCode, description: description)
            let data = try JSONEncoder().encode(renamedPreset)
            try data.write(to: newURL)
            logger.info("Renamed preset '\(oldPreset.name)' to '\(newName)'.")
            DispatchQueue.main.async { [weak self] in
                self?.loadPresetsFromDisk()
                if let self = self,
                    let updated = self.presets.first(where: { $0.id == oldPreset.id })
                {
                    self.selectPreset(updated)
                }
            }
        } catch {
            logger.error("Failed to rename preset: \(error.localizedDescription)")
        }
    }

    func deletePreset(_ preset: JSPreset) {
        let fileURL = presetsDirectory.appendingPathComponent(createPresetFileName(preset: preset))
        do {
            try fileManager.removeItem(at: fileURL)
            logger.info("Deleted preset '\(preset.name)'.")
            DispatchQueue.main.async { [weak self] in
                self?.loadPresetsFromDisk()
                if self?.selectedPreset?.id == preset.id {
                    if let first = self?.presets.first {
                        self?.selectPreset(first)
                    } else {
                        self?.selectedPreset = nil
                        self?.jsCode = ""
                        self?.title = ""
                        self?.description = ""
                    }
                }
            }
        } catch {
            logger.error("Failed to delete preset: \(error.localizedDescription)")
        }
    }

    func resetContext() -> Bool {
        // TODO: use a better log stream
        let logStreamFn: LogStream = { message in
            self.logger.info(message)
        }

        guard let engine = JavaScriptEngine(jsFunctionsCode: jsCode, logStream: logStreamFn) else {
            logger.error("Failed to create JavaScript engine")
            return false
        }
        self.context = engine
        logger.info("Reset context")
        return true
    }

    func runTest() {
        // ensure the context is initialized
        if context == nil {
            if !resetContext() {
                logger.error("Failed to reset context")
                return
            }
            // TODO show banner with error message
        }

        switch operation {
        case .read:
            guard context!.canRead else {
                logger.info("Read function not defined")
                return
            }
            let result = context!.runRead()
            logger.info("Read executed -> \(result)")
            lastResult = convertToString(data: result, to: self.resultType)
            logger.info("Read executed -> \(lastResult)")

        case .write:
            guard context!.canWrite else {
                logger.info("Write function not defined")
                return
            }
            let convertedInput = convertFromString(value: testInput, to: inputType)
            let result = context!.runWrite(value: convertedInput)
            lastResult = convertToString(data: result, to: self.resultType)
            logger.info("Write executed with input: \(testInput) -> \(lastResult)")

        case .notify:
            // not implemented yet
            lastResult = "Notify not implemented yet"
            logger.info("Notify executed.")
        }
    }

    func isValidPresetName(_ name: String) -> Bool {
        let allowed = CharacterSet.letters.union(CharacterSet(charactersIn: "-_"))
        return !name.isEmpty && name.rangeOfCharacter(from: allowed.inverted) == nil
    }

    func createPresetFileName(preset: JSPreset) -> String {
        return "\(preset.id)_\(preset.name).json"
    }

    func createNewPreset(_ name: String) {
        let preset = JSPreset(name: name)
        presets.append(preset)
        do {
            if !fileManager.fileExists(atPath: presetsDirectory.path) {
                try fileManager.createDirectory(
                    at: presetsDirectory, withIntermediateDirectories: true)
            }
            let fileURL = presetsDirectory.appendingPathComponent(
                createPresetFileName(preset: preset))
            let data = try JSONEncoder().encode(preset)
            try data.write(to: fileURL)
            logger.info("Created new preset '\(name)'.")
            DispatchQueue.main.async { [weak self] in
                self?.loadPresetsFromDisk()
                if let self = self, let created = self.presets.first(where: { $0.name == name }) {
                    self.selectPreset(created)
                }
            }
        } catch {
            logger.error("Failed to create preset: \(error.localizedDescription)")
        }
    }

    func loadExample() {
        let resourceName = "example"
        guard let fileURL = Bundle.main.url(forResource: resourceName, withExtension: "js") else {
            logger.error("Error: Could not find \(resourceName).js script")
            return
        }
        do {
            let script = try String(contentsOf: fileURL, encoding: .utf8)
            self.jsCode = script
        } catch {
            logger.error("Error loading script: \(error)")
        }
        self.resetContext()
    }
}
