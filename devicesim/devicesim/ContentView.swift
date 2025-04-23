//
//  ContentView.swift
//  devicesim
//
//  Created by Max Mönch on 19.04.25.
//

import SwiftUI
import AppKit
import CoreBluetooth

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var deviceSettings = DeviceSettings()
    @State private var selectedTab = 0
    @State private var messageToSend = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            mainView
                .tabItem {
                    Label("Main", systemImage: "antenna.radiowaves.left.and.right")
                }
                .tag(0)
            
            settingsView
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
            
            logView
                .tabItem {
                    Label("Logs", systemImage: "text.book.closed")
                }
                .tag(2)
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            // Connect device settings to the Bluetooth manager
            bluetoothManager.deviceSettings = deviceSettings
        }
    }
    
    // MARK: - Main View
    private var mainView: some View {
        VStack(spacing: 20) {
            // Bluetooth Status Section
            HStack {
                Image(systemName: bluetoothStateIcon)
                    .font(.system(size: 24))
                    .foregroundColor(bluetoothStateColor)
                
                VStack(alignment: .leading) {
                    Text("Bluetooth Status")
                        .font(.headline)
                    
                    Text(bluetoothManager.stateMessage)
                        .foregroundColor(bluetoothStateColor)
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
            
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 50))
                    .foregroundColor(bluetoothManager.isAdvertising ? .blue : .gray)
                
                VStack(alignment: .leading) {
                    Text("Bluetooth Device Simulator")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Status: \(bluetoothManager.isAdvertising ? "Advertising" : "Not Advertising")")
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
            
            // Message sending area
            VStack(alignment: .leading) {
                Text("Send Message")
                    .font(.headline)
                
                HStack {
                    TextField("Enter message to send", text: $messageToSend)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        if !messageToSend.isEmpty {
                            if let data = messageToSend.data(using: .utf8) {
                                bluetoothManager.sendData(data)
                                messageToSend = ""
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(messageToSend.isEmpty || bluetoothManager.connectedCentrals.isEmpty)
                }
                
                // Quick message templates
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(deviceSettings.savedMessages, id: \.self) { message in
                            Button(message) {
                                if let data = message.data(using: .utf8) {
                                    bluetoothManager.sendData(data)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Connected devices
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
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        Form {
            Section(header: Text("Device Configuration")) {
                TextField("Device Name", text: $deviceSettings.deviceName)
                TextField("Service UUID", text: $deviceSettings.serviceUUID)
                TextField("Characteristic UUID", text: $deviceSettings.characteristicUUID)
            }
            
            Section(header: Text("Auto Response")) {
                Toggle("Auto Respond to Requests", isOn: $deviceSettings.autoResponse)
                TextField("Auto Response Text", text: $deviceSettings.autoResponseText)
                    .disabled(!deviceSettings.autoResponse)
            }
            
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
        .padding()
    }
    
    // MARK: - Log View
    private var logView: some View {
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
    
    // Add computed properties for the Bluetooth status
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
    
    // Add method to open Bluetooth settings
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
