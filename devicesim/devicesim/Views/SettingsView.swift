import SwiftUI

struct SettingsView: View {
    @ObservedObject var deviceSettings: DeviceSettings
    @State private var messageToSend = ""
    @State private var isShowingSaveProfileSheet = false
    @State private var newProfileName = ""
    
    var body: some View {
        Form {
            ProfileManagementSection(
                deviceSettings: deviceSettings,
                isShowingSaveProfileSheet: $isShowingSaveProfileSheet,
                newProfileName: $newProfileName
            )

            DeviceConfigurationSection(deviceSettings: deviceSettings)
            
            AutoResponseSection(deviceSettings: deviceSettings)
            
            SavedMessagesSection(
                deviceSettings: deviceSettings,
                messageToSend: $messageToSend
            )
        }
        .padding()
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
