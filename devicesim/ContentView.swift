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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainView(
                bluetoothManager: bluetoothManager,
                deviceSettings: deviceSettings
            )
            .tabItem {
                Label("Main", systemImage: "antenna.radiowaves.left.and.right")
            }
            .tag(0)
            
            SettingsView(deviceSettings: deviceSettings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
            
            LogView(bluetoothManager: bluetoothManager)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
