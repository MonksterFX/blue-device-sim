import SwiftUI

struct JavaScriptExamplesView: View {
    @ObservedObject var deviceSettings: DeviceSettings
    @Environment(\.dismiss) private var dismiss
    
    // Sample JS read/write function stubs
    private let readStub = "// JS read function\nreturn 'Read value: ' + new Date().toISOString();"
    private let writeStub = "// JS write function\nconsole.log('Write value:', value); return true;"
    
    // Sample JS functions for different use cases
    private let examples = [
        Example(
            name: "Basic read/write functions",
            description: "Separate functions for read and write operations. Use the parameters as shown.",
            code: "// Read function\nfunction read(appStartTime, subscriptionTime) {\n    return 'Read value: ' + new Date().toISOString();\n}\n\n// Write function\nfunction write(appStartTime, subscriptionTime, value) {\n    console.log('Write value:', value);\n    return true;\n}"
        ),
        Example(
            name: "Time-based read, log write",
            description: "Read returns time since app start, write logs the value.",
            code: "// Read function\nfunction read(appStartTime, subscriptionTime) {\n    const now = new Date().getTime();\n    const appRuntime = Math.floor((now - appStartTime) / 1000);\n    return `App running for ${appRuntime} seconds`;\n}\n\n// Write function\nfunction write(appStartTime, subscriptionTime, value) {\n    console.log('Received write at', new Date().toISOString(), 'with value:', value);\n    return { status: 'ok', written: value };\n}"
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("JavaScript Function Examples")
                .font(.title2)
                .padding(.bottom, 10)
            Text("You must now define two separate functions: \n\n• read(appStartTime, subscriptionTime): called on read/notify\n• write(appStartTime, subscriptionTime, value): called on write\n\nIf you load an old profile, its single function will be used for both read and write. Edit as needed.")
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(examples) { example in
                        ExampleCard(example: example) {
                            // Insert both stubs into the settings
                            deviceSettings.characteristicJSReadFunction = readStub
                            deviceSettings.characteristicJSWriteFunction = writeStub
                            deviceSettings.useJSFunction = true
                            deviceSettings.saveSettings(as: deviceSettings.currentProfileName)
                            dismiss()
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            HStack {
                Spacer()
                Button("Insert Default Stubs") {
                    deviceSettings.characteristicJSReadFunction = readStub
                    deviceSettings.characteristicJSWriteFunction = writeStub
                    deviceSettings.useJSFunction = true
                    deviceSettings.saveSettings(as: deviceSettings.currentProfileName)
                    dismiss()
                }
                .buttonStyle(.bordered)
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}

// Model for JavaScript function examples
struct Example: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let code: String
}

// Card for displaying examples
struct ExampleCard: View {
    let example: Example
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(example.name)
                .font(.headline)
            
            Text(example.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView {
                Text(example.code)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 150)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                Spacer()
                Button("Use This Example") {
                    onSelect()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
} 