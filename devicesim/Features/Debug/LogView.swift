import SwiftUI
import Inject
struct LogView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObserveInjection var inject

    var body: some View {
        VStack {
            HStack {
                Text("Activity Log")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    bluetoothManager.logMessages.removeAll()
                }
                .buttonStyle(.bordered)
            }
            
            List {
                ForEach(bluetoothManager.logMessages) { logMessage in
                    Text(logMessage.fullMessage)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .padding()
        .enableInjection()
    }
} 
