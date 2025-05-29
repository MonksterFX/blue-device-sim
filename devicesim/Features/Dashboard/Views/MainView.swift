import CoreBluetooth
import SwiftUI

struct MainView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var deviceSettings: DeviceSettings
    @State private var messageToSend = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack {
                    BluetoothStatusSection(
                        bluetoothManager: bluetoothManager,
                        stateIcon: bluetoothStateIcon,
                        stateColor: bluetoothStateColor
                    )

                    DeviceStatusSection(bluetoothManager: bluetoothManager)
                }

                ConnectedDevicesSection(bluetoothManager: bluetoothManager)

            // MessageSendingSection(
            //     bluetoothManager: bluetoothManager,
            //     deviceSettings: deviceSettings,
            //     messageToSend: $messageToSend
            // )
            }
            Spacer()
        }
        .padding()
    }

    private var bluetoothStateIcon: String {
        switch bluetoothManager.bluetoothState {
        case .poweredOn: return "bluetooth"
        case .poweredOff: return "bluetooth.slash"
        case .unauthorized: return "lock.shield"
        default: return "exclamationmark.triangle"
        }
    }

    private var bluetoothStateColor: Color {
        switch bluetoothManager.bluetoothState {
        case .poweredOn: return .blue
        case .poweredOff: return .red
        case .unauthorized: return .orange
        default: return .yellow
        }
    }
}

// MARK: - Bluetooth Status Section
struct BluetoothStatusSection: View {
    let bluetoothManager: BluetoothManager
    let stateIcon: String
    let stateColor: Color

    var body: some View {
        HStack {
            Image(systemName: stateIcon)
                .font(.system(size: 24))
                .foregroundColor(stateColor)

            VStack(alignment: .leading) {
                Text("Bluetooth Status")
                    .font(.headline)

                Text(bluetoothManager.stateMessage)
                    .foregroundColor(stateColor)
            }

            Spacer()

            if bluetoothManager.bluetoothState != .poweredOn {
                Button("Open Settings") {
                    openBluetoothSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private func openBluetoothSettings() {
        let urlString: String
        if #available(macOS 13, *) {
            urlString = "x-apple.systempreferences:com.apple.Bluetooth-Settings.extension"
        } else {
            urlString = "x-apple.systempreferences:com.apple.preference.bluetooth"
        }

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Device Status Section
struct DeviceStatusSection: View {
    let bluetoothManager: BluetoothManager

    var body: some View {
        HStack {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundColor(bluetoothManager.isAdvertising ? .blue : .gray)

            VStack(alignment: .leading) {
                Text("Bluetooth Device Simulator")
                    .font(.title)
                    .fontWeight(.bold)

                Text(
                    "Status: \(bluetoothManager.isAdvertising ? "Advertising" : "Not Advertising")"
                )
                .foregroundColor(bluetoothManager.isAdvertising ? .green : .red)
            }

            Spacer()

            VStack {
                Button(action: {
                    if bluetoothManager.isAdvertising {
                        bluetoothManager.stopAdvertising()
                    } else {
                        bluetoothManager.startAdvertising()
                    }
                }) {
                    Text(bluetoothManager.isAdvertising ? "Stop Advertising" : "Start Advertising")
                        .frame(width: 150)
                }
                .buttonStyle(.borderedProminent)
                .disabled(bluetoothManager.bluetoothState != .poweredOn)

                Text("\(bluetoothManager.connectedCentrals.count) device(s) connected")
                    .font(.caption)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// // MARK: - Message Sending Section
// struct MessageSendingSection: View {
//     let bluetoothManager: BluetoothManager
//     let deviceSettings: DeviceSettings
//     @Binding var messageToSend: String

//     var body: some View {
//         VStack(alignment: .leading) {
//             Text("Send Message")
//                 .font(.headline)

//             HStack {
//                 TextField("Enter message to send", text: $messageToSend)
//                     .textFieldStyle(RoundedBorderTextFieldStyle())

//                 Button("Send") {
//                     if !messageToSend.isEmpty {
//                         if let data = messageToSend.data(using: .utf8) {
//                             bluetoothManager.sendData(data)
//                             messageToSend = ""
//                         }
//                     }
//                 }
//                 .buttonStyle(.borderedProminent)
//                 .disabled(messageToSend.isEmpty || bluetoothManager.connectedCentrals.isEmpty)
//             }

//             ScrollView(.horizontal) {
//                 HStack {
//                     ForEach(deviceSettings.savedMessages, id: \.self) { message in
//                         Button(message) {
//                             if let data = message.data(using: .utf8) {
//                                 bluetoothManager.sendData(data)
//                             }
//                         }
//                         .buttonStyle(.bordered)
//                     }
//                 }
//             }
//         }
//         .padding()
//         .background(Color.gray.opacity(0.1))
//         .cornerRadius(10)
//     }
// }

// MARK: - Connected Devices Section
struct ConnectedDevicesSection: View {
    let bluetoothManager: BluetoothManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Connected Devices")
                .font(.headline)

            if bluetoothManager.connectedCentrals.isEmpty {
                Text("No devices connected")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(bluetoothManager.connectedCentrals, id: \.identifier) { central in
                        HStack {
                            Image(systemName: "iphone")
                            Text(central.identifier.uuidString)
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
