import Foundation

class PresetRepository {
    private let fileManager = FileManager.default
    private var presetsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("JSFunctionPresets", isDirectory: true)
    }
    
    init() {
        createPresetsDirectoryIfNeeded()
    }
    
    private func createPresetsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: presetsDirectory.path) {
            try? fileManager.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)
        }
    }
    
    func savePreset(_ preset: JSPreset) throws {
        let fileURL = presetsDirectory.appendingPathComponent("\(preset.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(preset)
        try data.write(to: fileURL)
    }
    
    func loadPreset(id: UUID) throws -> JSPreset {
        let fileURL = presetsDirectory.appendingPathComponent("\(id.uuidString).json")
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(JSPreset.self, from: data)
    }
    
    func loadAllPresets() throws -> [JSPreset] {
        let fileURLs = try fileManager.contentsOfDirectory(at: presetsDirectory, includingPropertiesForKeys: nil)
        return try fileURLs.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(JSPreset.self, from: data)
        }
    }
    
    func deletePreset(id: UUID) throws {
        let fileURL = presetsDirectory.appendingPathComponent("\(id.uuidString).json")
        try fileManager.removeItem(at: fileURL)
    }
    
    func updatePreset(_ preset: JSPreset) throws {
        var updatedPreset = preset
        updatedPreset = JSPreset(id: preset.id, name: preset.name, code: preset.code)
        try savePreset(updatedPreset)
    }
}
