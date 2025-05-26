//
//  JSFunctionsAdminViewModel.swift
//  devicesim
//
//  Created by Max Mönch on 26.04.25.
//
import Foundation

struct JSPreset: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let code: String
    let description: String
    
    init(id: UUID = UUID(), name: String, code: String = "", description: String = "") {
        self.id = id
        self.name = name
        self.description = description
        self.code = code
    }
}

@Observable
class JSFunctionsAdminViewModel {
    var presets: [JSPreset] = []
    var selectedPreset: JSPreset? = nil
    var jsCode: String = ""
    var operation: OperationType = .read
    var testInput: String = ""
    var lastResult: String = ""
    var logStream: [String] = []
    var isRenaming: Bool = false
    var renameText: String = ""
    var presetToDelete: JSPreset? = nil
    var title: String = ""
    var description: String = ""
    var showInvalidNameAlert: Bool = false
    var showNewPresetAlert: Bool = false
    var newPresetName: String = ""
    var context: JavaScriptEngine? = nil
    
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
        logStream.append("Presets directory: \(presetsDirectory.path)")
        loadPresetsFromDisk()
    }
    
    func selectPreset(_ id: UUID){
        selectedPreset = presets.first(where: { $0.id == id })
    }
    
    func loadPresetsFromDisk() {
        do {
            if !fileManager.fileExists(atPath: presetsDirectory.path) {
                try fileManager.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)
            }
            let files = try fileManager.contentsOfDirectory(at: presetsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = files.filter { $0.pathExtension == "json" }
            let loadedPresets: [JSPreset] = jsonFiles.compactMap { url in
                guard let data = try? Data(contentsOf: url), let preset = try? JSONDecoder().decode(JSPreset.self, from: data) else { return nil }
                return preset
            }
            presets = loadedPresets
            if let first = presets.first {
                DispatchQueue.main.async { [weak self] in
                    self?.selectPreset(first)
                }
            }
        } catch {
            logStream.append("Failed to load presets: \(error.localizedDescription)")
        }
    }
    
    func selectPreset(_ preset: JSPreset) {
        selectedPreset = preset
        let fileURL = presetsDirectory.appendingPathComponent(createPresetFileName(preset: preset))
        if let data = try? Data(contentsOf: fileURL), let loaded = try? JSONDecoder().decode(JSPreset.self, from: data) {
            jsCode = loaded.code
            description = loaded.description
        } else {
            jsCode = ""
            description = ""
        }
    }
    
    func saveCurrentPreset() {
        guard let preset = selectedPreset else { return }
        guard isValidPresetName(preset.name) else {
            showInvalidNameAlert = true
            return
        }
        let updatedPreset = JSPreset(id: preset.id, name: preset.name, code: jsCode, description: description)
        do {
            if !fileManager.fileExists(atPath: presetsDirectory.path) {
                try fileManager.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)
            }
            let fileURL = presetsDirectory.appendingPathComponent(createPresetFileName(preset: preset))
            let data = try JSONEncoder().encode(updatedPreset)
            try data.write(to: fileURL)
            logStream.append("Saved preset '\(preset.name)' to disk.")
            DispatchQueue.main.async { [weak self] in
                self?.loadPresetsFromDisk()
            }
        } catch {
            logStream.append("Failed to save preset: \(error.localizedDescription)")
        }
    }
    
    func renamePreset(_ newName: String) {
        guard let oldPreset = selectedPreset, !newName.isEmpty, oldPreset.name != newName else { return }
        guard isValidPresetName(newName) else {
            showInvalidNameAlert = true
            return
        }
        // TODO: find by uuid
        let oldURL = presetsDirectory.appendingPathComponent("\(oldPreset.name).json")
        let newURL = presetsDirectory.appendingPathComponent("\(newName).json")
        do {
            if fileManager.fileExists(atPath: newURL.path) {
                logStream.append("A preset with that name already exists.")
                return
            }
            try fileManager.moveItem(at: oldURL, to: newURL)
            let renamedPreset = JSPreset(id: oldPreset.id, name: newName, code: jsCode, description: description)
            let data = try JSONEncoder().encode(renamedPreset)
            try data.write(to: newURL)
            logStream.append("Renamed preset '\(oldPreset.name)' to '\(newName)'.")
            DispatchQueue.main.async { [weak self] in
                self?.loadPresetsFromDisk()
                if let self = self, let updated = self.presets.first(where: { $0.id == oldPreset.id }) {
                    self.selectPreset(updated)
                }
            }
        } catch {
            logStream.append("Failed to rename preset: \(error.localizedDescription)")
        }
    }
    
    func deletePreset(_ preset: JSPreset) {
        let fileURL = presetsDirectory.appendingPathComponent(createPresetFileName(preset: preset))
        do {
            try fileManager.removeItem(at: fileURL)
            logStream.append("Deleted preset '\(preset.name)'.")
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
            logStream.append("Failed to delete preset: \(error.localizedDescription)")
        }
    }
    
    func resetContext() -> Bool {
        // TODO: use a better log stream
        let logStreamFn: LogStream = { message in
            self.logStream.append(message)
        }

        guard let engine = JavaScriptEngine(jsFunctionsCode: jsCode, logStream: logStreamFn) else {
            logStream.append("Failed to create JavaScript engine")
            return false
        }
        self.context = engine
        logStream.append("Reset context")
        return true
    }

    func runTest() {
        // ensure the context is initialized
        if context == nil {
            if !resetContext() {
                logStream.append("Failed to reset context")
                return
            }
            // TODO show banner with error message
        }

        switch operation {
        case .read:
            guard context!.canRead else {
                logStream.append("Read function not defined")
                return
            }
            lastResult = context!.runRead()
            logStream.append("Read executed -> \(lastResult)")

        case .write:
            guard context!.canWrite else {
                logStream.append("Write function not defined")
                return
            }
            lastResult = context!.runWrite(value: testInput)
            logStream.append("Write executed with input: \(testInput) -> \(lastResult)")

        case .notify:
            // not implemented yet
            lastResult = "Notify not implemented yet"
            logStream.append("Notify executed.")
        }
    }
    
    func isValidPresetName(_ name: String) -> Bool {
        let allowed = CharacterSet.letters.union(CharacterSet(charactersIn: "-_"))
        return !name.isEmpty && name.rangeOfCharacter(from: allowed.inverted) == nil
    }
    
    func createPresetFileName(preset: JSPreset) -> String{
        return "\(preset.id)_\(preset.name).json"
    }
    
    func createNewPreset(_ name: String) {
        let preset = JSPreset(name: name)
        presets.append(preset)
        do {
            if !fileManager.fileExists(atPath: presetsDirectory.path) {
                try fileManager.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)
            }
            let fileURL = presetsDirectory.appendingPathComponent(createPresetFileName(preset: preset))
            let data = try JSONEncoder().encode(preset)
            try data.write(to: fileURL)
            logStream.append("Created new preset '\(name)'.")
            DispatchQueue.main.async { [weak self] in
                self?.loadPresetsFromDisk()
                if let self = self, let created = self.presets.first(where: { $0.name == name }) {
                    self.selectPreset(created)
                }
            }
        } catch {
            logStream.append("Failed to create preset: \(error.localizedDescription)")
        }
    }

    func loadExample() {
        jsCode = """
        /**
        * @param {number} appStartTime - The time (in ms since epoch) when the app started
        * @param {number} subscriptionTime - The time (in ms since epoch) when the subscription started
        * @returns {string|number|object} The value to return to the client
        */
        function read(appStartTime, subscriptionTime) {
            // Return a string, number, or object
            return 'Read value: ' + new Date().toISOString();
        }

        /**
        * @param {number} appStartTime - The time (in ms since epoch) when the app started
        * @param {number} subscriptionTime - The time (in ms since epoch) when the subscription started
        * @param {string} value - The value written by the client
        * @returns {string|number|object|boolean} The result of the write operation
        */
        function write(appStartTime, subscriptionTime, value) {
            // Log the value and return a result
            console.log('Write value:', value);
            return true;
        }
        """
    }
}
