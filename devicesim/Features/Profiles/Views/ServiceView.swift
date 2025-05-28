import SwiftUI

struct ServiceView: View {
    @Binding var service: CustomBleService

    var body: some View {

        Divider().padding(.vertical)

        GridRow {
            RectangularIcon(letter: "C")
            Text(service.name).font(.headline).gridColumnAlignment(.leading)
        }

        GridRow {
            Text("Name").gridColumnAlignment(.trailing)
            InputField(
                value: Binding(
                    get: { service.name },
                    set: { service.name = $0 }
                )
            )
        }

        ForEach(service.characteristics, id: \.uuid) { characteristic in
            CharacteristicView(
                characteristic: Binding(
                    get: { characteristic },
                    set: { newValue in
                        if let index = service.characteristics.firstIndex(where: {
                            $0.uuid == characteristic.uuid
                        }) {
                            service.characteristics[index] = newValue
                        }
                    }
                ))
        }
    }
}
