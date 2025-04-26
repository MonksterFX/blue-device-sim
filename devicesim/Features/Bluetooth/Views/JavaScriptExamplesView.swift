import SwiftUI

struct JavaScriptExamplesView: View {
    @ObservedObject var deviceSettings: DeviceSettings
    @Environment(\.dismiss) private var dismiss
    
    // Sample JS functions for different use cases
    private let examples = [
        Example(
            name: "Basic read/notify function",
            description: "Simple function that returns different values for read vs. notify operations",
            code: """
            // Return different values for read vs notify
            if (isRead) {
                return "This is a read value";
            } else {
                return "This is a notification at " + new Date().toISOString();
            }
            """
        ),
        Example(
            name: "Time-based value",
            description: "Returns values based on time since app started and subscription",
            code: """
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
                return `Notification - Subscribed for ${subscriptionRuntime} seconds`;
            }
            """
        ),
        Example(
            name: "Simulated sensor data (JSON)",
            description: "Returns JSON data simulating a sensor with random noise",
            code: """
            // Generate simulated sensor data as JSON
            const now = new Date().getTime();
            
            // Base value + random noise + sine wave
            const subscriptionSecs = subscriptionTime ? (now - subscriptionTime) / 1000 : 0;
            const baseValue = 25.0;
            const noise = Math.random() * 0.5;
            const wave = Math.sin(subscriptionSecs * 0.1) * 2;
            
            // Calculate the final value
            const sensorValue = baseValue + noise + wave;
            
            // Return a data object
            return {
                timestamp: now,
                value: sensorValue.toFixed(2),
                unit: "°C",
                type: isRead ? "read" : "notification",
                battery: 85 - (subscriptionSecs * 0.01)
            };
            """
        ),
        Example(
            name: "Counter with battery simulation",
            description: "Simulates a device with a counter and decreasing battery",
            code: """
            // Simple counter with battery level simulation
            const now = new Date().getTime();
            const appRuntimeMins = (now - appStartTime) / (1000 * 60);
            
            // Counter increases each notification
            let counter = isRead ? 0 : Math.floor((now - subscriptionTime) / (deviceSettings.notifyInterval * 1000));
            
            // Battery decreases over time (100% to 0% in about 8 hours)
            const batteryLevel = Math.max(0, Math.floor(100 - (appRuntimeMins / 4.8)));
            
            return {
                counter: counter,
                battery: batteryLevel,
                timestamp: now,
                mode: isRead ? "read" : "notify"
            };
            """
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("JavaScript Function Examples")
                .font(.title2)
                .padding(.bottom, 10)
            
            Text("Select an example to use as a starting point for your characteristic function.")
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(examples) { example in
                        ExampleCard(example: example) {
                            deviceSettings.characteristicJSFunction = example.code
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