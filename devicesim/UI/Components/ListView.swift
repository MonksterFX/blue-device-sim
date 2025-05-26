import SwiftUI

struct ListView<Item: Identifiable>: View {
    let items: [Item]
    let getName: (Item) -> String
    let onSelect: (Item.ID) -> Void
    
    var body: some View {
        List {
            ForEach(items) { item in
                Text(getName(item))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(item.id)
                    }
            }
        }
        .listStyle(.sidebar)
    }
} 