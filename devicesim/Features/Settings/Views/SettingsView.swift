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
    
    @State private var testResult: String = ""
    @State private var testLogs: [String] = []
    @State private var isTestingInterval = false
    @State private var intervalTimer: Timer? = nil
    @State private var codeEditorHeight: CGFloat = 200
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        Section(header: Text("JavaScript Handler")) {
            Toggle("Use JavaScript Function", isOn: $deviceSettings.useJSFunction)
            
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
                    Text("JavaScript Function")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("See Examples") {
                        isShowingJSExamplesSheet = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                VStack(spacing: 0) {
                    TextEditor(text: $deviceSettings.characteristicJSFunction)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: codeEditorHeight)
                        .border(Color.gray.opacity(0.3))
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.height
                                }
                                .onChanged { value in
                                    let newHeight = max(100, codeEditorHeight + value.translation.height)
                                    codeEditorHeight = newHeight
                                }
                        )
                        .overlay(
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 12))
                                .foregroundColor(.gray), alignment: .center
                        )
                }
                .cornerRadius(4)
                .padding(.bottom, 4)
                
                // --- Test Panel ---
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Button("Test Read") {
                            runJSTest(isRead: true)
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
                    }
                    
                    Text("Result:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(testResult)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(6)
                    }
                    .frame(height: 60)
                    
                    Text("Console.log output:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(testLogs, id: \.self) { log in
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
                
                Text("Available JavaScript Context")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• appStartTime: Application start time in milliseconds")
                        .font(.caption)
                    Text("• subscriptionTime: First subscription time in milliseconds")
                        .font(.caption)
                    Text("• isRead: true for read requests, false for notifications")
                        .font(.caption)
                    Text("• Return value as string, number or object to send to client")
                        .font(.caption)
                }
                .padding(.leading, 10)
                
                // Example button
                Button("Insert Example Function") {
                    deviceSettings.characteristicJSFunction = """
                    // Calculate time difference in seconds
                    const now = new Date().getTime();
                    const appRuntime = Math.floor((now - appStartTime) / 1000);
                    let subscriptionRuntime = 0;
                    
                    if (subscriptionTime) {
                        subscriptionRuntime = Math.floor((now - subscriptionTime) / 1000);
                    }
                    
                    // Different responses for read vs notify
                    if (isRead) {
                        return `Read value - App running for ${appRuntime} seconds`;
                    } else {
                        // For notifications, return a dynamic value
                        return {
                            timestamp: now,
                            subscribed_for: subscriptionRuntime,
                            operation: "notification",
                            value: Math.sin(subscriptionRuntime * 0.1) * 100
                        };
                    }
                    """
                }
                .buttonStyle(.bordered)
                .padding(.top, 5)
            }
        }
    }
    
    // --- JS Test Harness ---
    private func runJSTest(isRead: Bool) {
        testLogs = []
        let (result, logs) = JavaScriptTestHarness.run(
            jsFunction: deviceSettings.characteristicJSFunction,
            isRead: isRead,
            notifyInterval: deviceSettings.notifyInterval
        )
        testResult = result
        testLogs = logs
    }
    
    private func startIntervalTest() {
        testLogs = []
        testResult = ""
        isTestingInterval = true
        var count = 0
        let startTime = Date()
        intervalTimer = Timer.scheduledTimer(withTimeInterval: deviceSettings.notifyInterval, repeats: true) { _ in
            let (result, logs) = JavaScriptTestHarness.run(
                jsFunction: deviceSettings.characteristicJSFunction,
                isRead: false,
                notifyInterval: deviceSettings.notifyInterval,
                appStartTime: startTime,
                subscriptionTime: startTime
            )
            testResult = result
            testLogs = logs
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
        // Capture console.log
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
        // Add the function
        context.evaluateScript("""
        function evaluateCharacteristicFunction(appStartTime, subscriptionTime, isRead) {
            \(jsFunction)
        }
        """)
        // Prepare arguments
        let appStartTimeMs = appStartTime.timeIntervalSince1970 * 1000
        let subscriptionTimeMs = subscriptionTime.timeIntervalSince1970 * 1000
        let jsCall = "evaluateCharacteristicFunction(\(appStartTimeMs), \(subscriptionTimeMs), \(isRead))"
        let result = context.evaluateScript(jsCall)
        var resultString = ""
        if let result = result {
            if result.isString {
                resultString = result.toString() ?? ""
            } else if result.isNumber {
                resultString = "\(result.toNumber() ?? 0)"
            } else if result.isObject {
                let stringifyCall = "JSON.stringify(evaluateCharacteristicFunction(\(appStartTimeMs), \(subscriptionTimeMs), \(isRead)))"
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
