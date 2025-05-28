import SwiftUI

struct LogView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    
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
    }
} 