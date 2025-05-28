import SwiftUI

struct Dropdown<T: Hashable>: View {
    let items: [T]

    @Binding var selectedItem: T?

    let keyPath: KeyPath<T, String>
    let onSelect: (T) -> Void

    var body: some View {
        Picker("Select Profile", selection: $selectedItem) {
            ForEach(items, id: \.self) { item in
                Text(item[keyPath: keyPath]).tag(item)
            }
        }
    }
}