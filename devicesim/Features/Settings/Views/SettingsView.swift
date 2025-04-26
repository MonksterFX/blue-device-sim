import SwiftUI
import JavaScriptCore

struct SettingsView: View {
    @ObservedObject var deviceSettings: DeviceSettings
    @State private var messageToSend = ""
    @State private var isShowingSaveProfileSheet = false
    @State private var isShowingJSExamplesSheet = false
    @State private var newProfileName = ""
    
    var body: some View {
        ScrollView {
            Form {
                ProfileManagementSection(
                    deviceSettings: deviceSettings,
                    isShowingSaveProfileSheet: $isShowingSaveProfileSheet,
                    newProfileName: $newProfileName
                )

                DeviceConfigurationSection(deviceSettings: deviceSettings)
                
                AutoResponseSection(deviceSettings: deviceSettings)
                
                JavaScriptFunctionSection(
                    deviceSettings: deviceSettings,
                    isShowingJSExamplesSheet: $isShowingJSExamplesSheet
                )
                
                SavedMessagesSection(
                    deviceSettings: deviceSettings,
                    messageToSend: $messageToSend
                )
            }
            .padding()
        }
        .sheet(isPresented: $isShowingSaveProfileSheet) {
            SaveProfileSheet(
                isPresented: $isShowingSaveProfileSheet,
                profileName: $newProfileName,
                onSave: {
                    if !newProfileName.isEmpty {
                        deviceSettings.saveSettings(as: newProfileName)
                        newProfileName = ""
                    }
                }
            )
        }
        .sheet(isPresented: $isShowingJSExamplesSheet) {
            JavaScriptExamplesView(deviceSettings: deviceSettings)
        }
    }
}

// MARK: - Save Profile Sheet
struct SaveProfileSheet: View {
    @Binding var isPresented: Bool
    @Binding var profileName: String
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Save Profile As")
                .font(.headline)
            
            TextField("Profile Name", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    onSave()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(profileName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 150)
    }
}

// MARK: - Profile Management Section
struct ProfileManagementSection: View {
    let deviceSettings: DeviceSettings
    @Binding var isShowingSaveProfileSheet: Bool
    @Binding var newProfileName: String
    
    var body: some View {
        Section(header: Text("Profile Management")) {
            HStack {
                Text("Current Profile: \(deviceSettings.currentProfileName)")
                    .fontWeight(.medium)
                Spacer()
                Button("Save As...") {
                    isShowingSaveProfileSheet = true
                }
                .buttonStyle(.bordered)
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 10) {
                    ForEach(deviceSettings.listProfiles(), id: \.name) { profile in
                        ProfileButton(
                            profileName: profile.name,
                            isActive: profile.name == deviceSettings.currentProfileName,
                            createdAt: profile.createdAt
                        ) {
                            deviceSettings.loadSettings(profile: profile.name)
                        } onDelete: {
                            deviceSettings.deleteProfile(profile.name)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
            .frame(height: 80)
        }
    }
}

// MARK: - Device Configuration Section
struct DeviceConfigurationSection: View {
    @ObservedObject var deviceSettings: DeviceSettings
    
    var body: some View {
        Section(header: Text("Device Configuration")) {
            TextField("Device Name", text: $deviceSettings.deviceName)
            TextField("Service UUID", text: $deviceSettings.serviceUUID)
            TextField("Characteristic UUID", text: $deviceSettings.characteristicUUID)
        }
    }
}

// MARK: - Auto Response Section
struct AutoResponseSection: View {
    @ObservedObject var deviceSettings: DeviceSettings
    
    var body: some View {
        Section(header: Text("Auto Response")) {
            Toggle("Auto Respond to Requests", isOn: $deviceSettings.autoResponse)
            TextField("Auto Response Text", text: $deviceSettings.autoResponseText)
                .disabled(!deviceSettings.autoResponse)
        }
    }
}

// MARK: - JavaScript Function Section
struct JavaScriptFunctionSection: View {
    @ObservedObject var deviceSettings: DeviceSettings
    
    @Binding var isShowingJSExamplesSheet: Bool
    
    @State private var testReadResult: String = ""
    @State private var testReadLogs: [String] = []
    @State private var testWriteResult: String = ""
    @State private var testWriteLogs: [String] = []
    @State private var isTestingInterval = false
    @State private var intervalTimer: Timer? = nil
    @State private var codeEditorHeight: CGFloat = 200
    @State private var testWriteInput: String = "test-value"
    @State private var jsFunctionsCode: String = "// Define both functions below\nfunction read(appStartTime, subscriptionTime) {\n    return 'Read value: ' + new Date().toISOString();\n}\n\nfunction write(appStartTime, subscriptionTime, value) {\n    console.log('Write value:', value);\n    return true;\n}"
    
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        Section(header: Text("JavaScript Handler")) {
            Toggle("Use JavaScript Functions", isOn: $deviceSettings.useJSFunction)
            
            if deviceSettings.useJSFunction {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Notification Interval (seconds)")
                    HStack {
                        Slider(value: $deviceSettings.notifyInterval, in: 0.1...10.0, step: 0.1)
                        Text(String(format: "%.1f", deviceSettings.notifyInterval))
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                }
                
                HStack {
                    Text("JavaScript Functions (define both read and write)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Insert Default Stubs") {
                        jsFunctionsCode = "// Define both functions below\nfunction read(appStartTime, subscriptionTime) {\n    return 'Read value: ' + new Date().toISOString();\n}\n\nfunction write(appStartTime, subscriptionTime, value) {\n    console.log('Write value:', value);\n    return true;\n}"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                JSCodeEditor(code: $jsFunctionsCode)
                
                // --- Test Panel ---
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Write Test Value:")
                            .font(.caption)
                        TextField("Enter value", text: $testWriteInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                    }
                    HStack(spacing: 12) {
                        Button("Test Read") {
                            runJSTestRead()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isTestingInterval)
                        
                        Button(isTestingInterval ? "Stop Interval Test" : "Test Notify (Interval)") {
                            if isTestingInterval {
                                stopIntervalTest()
                            } else {
                                startIntervalTest()
                            }
                        }
                        .buttonStyle(.bordered)
                        Button("Test Write") {
                            runJSTestWrite()
                        }
                        .buttonStyle(.bordered)
                    }
                    Text("Read Result:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(testReadResult)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(6)
                    }
                    .frame(height: 60)
                    Text("Read Console.log output:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(testReadLogs, id: \.self) { log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(6)
                    }
                    .frame(height: 60)
                    Text("Write Result:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(testWriteResult)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(6)
                    }
                    .frame(height: 60)
                    Text("Write Console.log output:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(testWriteLogs, id: \.self) { log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(6)
                    }
                    .frame(height: 60)
                }
                .padding(.vertical, 8)
                
                Text("Available JavaScript Function Signatures")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                VStack(alignment: .leading, spacing: 4) {
                    Text("• read(appStartTime: number, subscriptionTime: number): any")
                        .font(.caption)
                    Text("• write(appStartTime: number, subscriptionTime: number, value: string): any")
                        .font(.caption)
                    Text("• Return value as string, number or object to send to client")
                        .font(.caption)
                }
                .padding(.leading, 10)
            }
        }
    }
    // --- JS Test Harness ---
    private func runJSTestRead() {
        testReadLogs = []
        let (result, logs) = JavaScriptTestHarness.runReadFromCombinedCode(
            jsFunctionsCode: jsFunctionsCode,
            notifyInterval: deviceSettings.notifyInterval
        )
        testReadResult = result
        testReadLogs = logs
    }
    private func runJSTestWrite() {
        testWriteLogs = []
        let (result, logs) = JavaScriptTestHarness.runWriteFromCombinedCode(
            jsFunctionsCode: jsFunctionsCode,
            value: testWriteInput,
            notifyInterval: deviceSettings.notifyInterval
        )
        testWriteResult = result
        testWriteLogs = logs
    }
    private func startIntervalTest() {
        testReadLogs = []
        testReadResult = ""
        isTestingInterval = true
        var count = 0
        let startTime = Date()
        intervalTimer = Timer.scheduledTimer(withTimeInterval: deviceSettings.notifyInterval, repeats: true) { _ in
            let (result, logs) = JavaScriptTestHarness.runReadFromCombinedCode(
                jsFunctionsCode: jsFunctionsCode,
                notifyInterval: deviceSettings.notifyInterval,
                appStartTime: startTime,
                subscriptionTime: startTime
            )
            testReadResult = result
            testReadLogs = logs
            count += 1
            if count >= 10 { // Stop after 10 intervals
                stopIntervalTest()
            }
        }
    }
    private func stopIntervalTest() {
        intervalTimer?.invalidate()
        intervalTimer = nil
        isTestingInterval = false
    }
}

// --- JS Test Harness Helper ---
struct JavaScriptTestHarness {
    static func run(jsFunction: String, isRead: Bool, notifyInterval: Double, appStartTime: Date = Date(), subscriptionTime: Date = Date()) -> (String, [String]) {
        var logs: [String] = []
        let context = JSContext()!
        let consoleLog: @convention(block) (String) -> Void = { message in
            logs.append(message)
        }
        context.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
        context.evaluateScript("console = { log: consoleLog }")
        context.exceptionHandler = { _, exception in
            if let exc = exception {
                logs.append("JS Error: \(exc.toString() ?? "Unknown error")")
            }
        }
        // Add the function as a read or write function
        if isRead {
            context.evaluateScript("function read(appStartTime, subscriptionTime) {\n\(jsFunction)\n}")
        } else {
            context.evaluateScript("function write(appStartTime, subscriptionTime, value) {\n\(jsFunction)\n}")
        }
        let appStartTimeMs = appStartTime.timeIntervalSince1970 * 1000
        let subscriptionTimeMs = subscriptionTime.timeIntervalSince1970 * 1000
        let jsCall: String
        if isRead {
            jsCall = "read(\(appStartTimeMs), \(subscriptionTimeMs))"
        } else {
            jsCall = "write(\(appStartTimeMs), \(subscriptionTimeMs), 'test-value')"
        }
        let result = context.evaluateScript(jsCall)
        var resultString = ""
        if let result = result {
            if result.isString {
                resultString = result.toString() ?? ""
            } else if result.isNumber {
                resultString = "\(result.toNumber() ?? 0)"
            } else if result.isObject {
                let stringifyCall = "JSON.stringify(\(jsCall))"
                let jsonResult = context.evaluateScript(stringifyCall)
                resultString = jsonResult?.toString() ?? "[object]"
            } else if result.isUndefined || result.isNull {
                resultString = "undefined"
            } else {
                resultString = result.toString() ?? ""
            }
        }
        return (resultString, logs)
    }
    
    static func runRead(jsReadFunction: String, notifyInterval: Double, appStartTime: Date = Date(), subscriptionTime: Date = Date()) -> (String, [String]) {
        return run(jsFunction: jsReadFunction, isRead: true, notifyInterval: notifyInterval, appStartTime: appStartTime, subscriptionTime: subscriptionTime)
    }
    
    static func runWrite(jsWriteFunction: String, value: String, notifyInterval: Double, appStartTime: Date = Date(), subscriptionTime: Date = Date()) -> (String, [String]) {
        var logs: [String] = []
        let context = JSContext()!
        let consoleLog: @convention(block) (String) -> Void = { message in
            logs.append(message)
        }
        context.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
        context.evaluateScript("console = { log: consoleLog }")
        context.exceptionHandler = { _, exception in
            if let exc = exception {
                logs.append("JS Error: \(exc.toString() ?? "Unknown error")")
            }
        }
        context.evaluateScript("function write(appStartTime, subscriptionTime, value) {\n\(jsWriteFunction)\n}")
        let appStartTimeMs = appStartTime.timeIntervalSince1970 * 1000
        let subscriptionTimeMs = subscriptionTime.timeIntervalSince1970 * 1000
        let jsCall = "write(\(appStartTimeMs), \(subscriptionTimeMs), 'test-value')"
        let result = context.evaluateScript(jsCall)
        var resultString = ""
        if let result = result {
            if result.isString {
                resultString = result.toString() ?? ""
            } else if result.isNumber {
                resultString = "\(result.toNumber() ?? 0)"
            } else if result.isObject {
                let stringifyCall = "JSON.stringify(\(jsCall))"
                let jsonResult = context.evaluateScript(stringifyCall)
                resultString = jsonResult?.toString() ?? "[object]"
            } else if result.isUndefined || result.isNull {
                resultString = "undefined"
            } else {
                resultString = result.toString() ?? ""
            }
        }
        return (resultString, logs)
    }
    
    static func runReadFromCombinedCode(jsFunctionsCode: String, notifyInterval: Double, appStartTime: Date = Date(), subscriptionTime: Date = Date()) -> (String, [String]) {
        var logs: [String] = []
        let context = JSContext()!
        let consoleLog: @convention(block) (String) -> Void = { message in
            logs.append(message)
        }
        context.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
        context.evaluateScript("console = { log: consoleLog }")
        context.exceptionHandler = { _, exception in
            if let exc = exception {
                logs.append("JS Error: \(exc.toString() ?? "Unknown error")")
            }
        }
        // Evaluate the combined code (should define both functions)
        context.evaluateScript(jsFunctionsCode)
        let appStartTimeMs = appStartTime.timeIntervalSince1970 * 1000
        let subscriptionTimeMs = subscriptionTime.timeIntervalSince1970 * 1000
        let jsCall = "read(\(appStartTimeMs), \(subscriptionTimeMs))"
        let result = context.evaluateScript(jsCall)
        var resultString = ""
        if let result = result {
            if result.isString {
                resultString = result.toString() ?? ""
            } else if result.isNumber {
                resultString = "\(result.toNumber() ?? 0)"
            } else if result.isObject {
                let stringifyCall = "JSON.stringify(\(jsCall))"
                let jsonResult = context.evaluateScript(stringifyCall)
                resultString = jsonResult?.toString() ?? "[object]"
            } else if result.isUndefined || result.isNull {
                resultString = "undefined"
            } else {
                resultString = result.toString() ?? ""
            }
        }
        return (resultString, logs)
    }
    
    static func runWriteFromCombinedCode(jsFunctionsCode: String, value: String, notifyInterval: Double, appStartTime: Date = Date(), subscriptionTime: Date = Date()) -> (String, [String]) {
        var logs: [String] = []
        let context = JSContext()!
        let consoleLog: @convention(block) (String) -> Void = { message in
            logs.append(message)
        }
        context.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
        context.evaluateScript("console = { log: consoleLog }")
        context.exceptionHandler = { _, exception in
            if let exc = exception {
                logs.append("JS Error: \(exc.toString() ?? "Unknown error")")
            }
        }
        // Evaluate the combined code (should define both functions)
        context.evaluateScript(jsFunctionsCode)
        let appStartTimeMs = appStartTime.timeIntervalSince1970 * 1000
        let subscriptionTimeMs = subscriptionTime.timeIntervalSince1970 * 1000
        // Escape value for JS string
        let escapedValue = value.replacingOccurrences(of: "'", with: "\\'")
        let jsCall = "write(\(appStartTimeMs), \(subscriptionTimeMs), '\(escapedValue)')"
        let result = context.evaluateScript(jsCall)
        var resultString = ""
        if let result = result {
            if result.isString {
                resultString = result.toString() ?? ""
            } else if result.isNumber {
                resultString = "\(result.toNumber() ?? 0)"
            } else if result.isObject {
                let stringifyCall = "JSON.stringify(\(jsCall))"
                let jsonResult = context.evaluateScript(stringifyCall)
                resultString = jsonResult?.toString() ?? "[object]"
            } else if result.isUndefined || result.isNull {
                resultString = "undefined"
            } else {
                resultString = result.toString() ?? ""
            }
        }
        return (resultString, logs)
    }
}

// MARK: - Saved Messages Section
struct SavedMessagesSection: View {
    @ObservedObject var deviceSettings: DeviceSettings
    @Binding var messageToSend: String
    
    var body: some View {
        Section(header: Text("Saved Messages")) {
            ForEach(deviceSettings.savedMessages.indices, id: \.self) { index in
                HStack {
                    Text(deviceSettings.savedMessages[index])
                    Spacer()
                    Button(action: {
                        deviceSettings.removeSavedMessage(at: index)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            HStack {
                TextField("New Message", text: $messageToSend)
                Button("Add") {
                    deviceSettings.addSavedMessage(messageToSend)
                    messageToSend = ""
                }
                .disabled(messageToSend.isEmpty)
            }
        }
    }
} 
