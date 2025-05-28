import SwiftUI

struct CharacteristicView: View {
    @Binding var characteristic: CustomBleCharacteristic

    var body: some View {

        Divider().padding(.vertical)

        GridRow {
            RectangularIcon(letter: "C")
            Text(characteristic.name).font(.headline).gridColumnAlignment(.leading)
        }

        GridRow {
            Text("UUID").gridColumnAlignment(.trailing).padding(.leading, 20)
            Text(characteristic.uuid.uuidString).gridColumnAlignment(.leading)
        }

        GridRow {
            Text("Name").gridColumnAlignment(.trailing).padding(.leading, 20)
            InputField(
                value: Binding(
                    get: { characteristic.name },
                    set: { characteristic.name = $0 }
                )
            )
        }

    }
}
