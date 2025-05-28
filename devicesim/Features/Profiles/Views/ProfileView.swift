import Inject
import SwiftUI

struct ProfileView: View {
    @ObserveInjection var inject
    @Bindable private var viewModel = ProfilesViewModel()

    // Profile Editor
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Profile Editor")
                    .font(.headline)

                Spacer()

                // Question: Why selected Item is optional?
                Dropdown(
                    items: viewModel.profiles, selectedItem: $viewModel.selectedProfile,
                    keyPath: \.name,
                    onSelect: { profile in
                        viewModel.selectProfile(profile: profile)
                    })
            }

            // Static Form Fields from Ble Profile
            if let profile = viewModel.selectedProfile {
                Text(profile.uuid.uuidString)
                
                Section(header: Text("Profile Information").font(.headline)) {
                    // Question: Why is this so complicated?
                    InputField(
                        value: Binding(
                            get: { profile.name },
                            set: { viewModel.selectedProfile?.name = $0 }
                        ),
                        label: "Profile Name"
                    )
                    
                    InputField(
                        value: Binding(
                            get: { profile.deviceName },
                            set: { viewModel.selectedProfile?.deviceName = $0 }
                        ),
                        label: "Device Name"
                    )
                }

                Grid {
                    ForEach(profile.services, id: \.uuid) { service in
                        ServiceView(service: Binding(
                            get: { service },
                            set: { newValue in
                                if let index = profile.services.firstIndex(where: { $0.uuid == service.uuid }) {
                                    viewModel.selectedProfile?.services[index] = newValue
                                }
                            }
                        ))

                        Divider().padding(.vertical)
                    }
                }

            }
            Spacer()
        }.enableInjection()
    }
}
