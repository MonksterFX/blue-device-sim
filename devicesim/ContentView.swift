//
//  ContentView.swift
//  devicesim
//
//  Created by Max Mönch on 19.04.25.
//

import SwiftUI
import AppKit
import CoreBluetooth
import Combine

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var deviceSettings = DeviceSettings()
    @StateObject private var viewModel = ContentViewModel()
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            // HStack {
            //     Spacer()
            //     Button(action: {
            //         let fileManager = FileManager.default
            //         let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            //         let presetsURL = documentsPath.appendingPathComponent("JSFunctionPresets", isDirectory: true)
            //         let profilesURL = documentsPath.appendingPathComponent("DeviceSim", isDirectory: true)
            //         NSWorkspace.shared.open(presetsURL)
            //         NSWorkspace.shared.open(profilesURL)
            //     }) {
            //         Label("Open Storage Folder", systemImage: "folder")
            //     }
            //     .help("Open the storage folders for presets and profiles in Finder")
            // }
            TabView(selection: $selectedTab) {
                MainView(
                    bluetoothManager: bluetoothManager,
                    deviceSettings: deviceSettings
                )
                .tabItem {
                    Label("Main", systemImage: "antenna.radiowaves.left.and.right")
                }
                .tag(0)

                ProfileView()
                    .tabItem {
                        Label("Profiles", systemImage: "list.bullet")
                    }
                .tag(1)

                // SettingsView(deviceSettings: deviceSettings)
                //     .tabItem {
                //         Label("Settings", systemImage: "gear")
                //     }
                //     .tag(2)
                
                LogPage()
                    .tabItem {
                        Label("Logs", systemImage: "text.book.closed")
                    }
                    .tag(2)

                JSFunctionsAdminView()
                    .tabItem {
                        Label("JS Admin", systemImage: "curlybraces.square")
                    }
                    .tag(3)
            }
            .padding()
            .frame(minWidth: 600, minHeight: 400)
            .onAppear {
                // // Connect device settings to the Bluetooth manager
                // bluetoothManager.deviceSettings = deviceSettings
                
                // // Setup observers using the ViewModel
                // viewModel.setupSettingsObservers(deviceSettings: deviceSettings, bluetoothManager: bluetoothManager)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
