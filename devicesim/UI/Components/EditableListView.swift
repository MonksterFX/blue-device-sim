import SwiftUI

struct EditableListView<Item: Identifiable & Hashable>: View {
    @State private var isRenaming: Bool = false
    @State private var renameText: String = ""
    @State private var itemToRename: Item? = nil
    @State private var newItemName: String = ""
    @State private var showNewItemAlert: Bool = false
    @State private var itemToDelete: Item? = nil
    @State private var selectedItem: Item? = nil
    
    // from parent
    var items: [Item]
    
    let getName: (Item) -> String
    let onAdd: (String) -> Void
    let onDelete: (Item) -> Void
    let onSelect: (Item) -> Void
    let onRename: (Item, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Items")
                    .font(.headline)
                Spacer()
                Button(action: {
                    newItemName = ""
                    showNewItemAlert = true
                }) {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
            
            List(selection: $selectedItem) {
                ForEach(items) { item in
                    HStack{
                        Text(getName(item))
                        Spacer()
                        Button(action: {
                            itemToRename = item
                            renameText = getName(item)
                            isRenaming = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)
                        Button(action: {
                            itemToDelete = item
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                    .contentShape(Rectangle())
                    .padding(6)
                    .background(selectedItem?.id == item.id ? Color.indigo : Color.red)
                    .cornerRadius(5)
                    .onTapGesture {
                        selectedItem = item
                        onSelect(item)
                    }
                }
            }
            .alert("Rename Item", isPresented: $isRenaming, actions: {
                TextField("New name", text: $renameText)
                Button("Rename") {
                    if let oldItem = itemToRename, !renameText.isEmpty {
                        onRename(oldItem, renameText)
                        itemToRename = nil
                    }
                    isRenaming = false
                }
                Button("Cancel", role: .cancel) {
                    isRenaming = false
                }
            }, message: {
                Text("Enter a new name for the item.")
            })
            .alert("Add New Item", isPresented: $showNewItemAlert, actions: {
                TextField("Item name", text: $newItemName)
                Button("Add") {
                    if !newItemName.isEmpty {
                        onAdd(newItemName)
                        newItemName = ""
                    }
                    showNewItemAlert = false
                }
                Button("Cancel", role: .cancel) {
                    showNewItemAlert = false
                }
            }, message: {
                Text("Enter a name for the new item.")
            })
            .alert("Delete Item?", isPresented: Binding<Bool>(
                get: { itemToDelete != nil },
                set: { if !$0 { itemToDelete = nil } }
            ), actions: {
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        onDelete(item)
                        itemToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
            }, message: {
                Text("Are you sure you want to delete this item?")
            })
        }
        .padding()
    }
}

// MARK: Preview
private struct DemoItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
}

struct EditableListView_Previews: PreviewProvider {
    struct DemoWrapper: View {
        @State private var demoItems: [DemoItem] = [
            DemoItem(name: "Item 1"),
            DemoItem(name: "Item 2"),
            DemoItem(name: "Item 3")
        ]
        @State private var selected: DemoItem? = nil
        var body: some View {
            EditableListView<DemoItem>(
                items: demoItems,
                getName: { $0.name },
                onAdd: { name in demoItems.append(DemoItem(name: name)) },
                onDelete: { item in demoItems.removeAll { $0.id == item.id } },
                onSelect: { item in selected = item },
                onRename: { item, newName in
                    if let idx = demoItems.firstIndex(where: { $0.id == item.id }) {
                        demoItems[idx].name = newName
                    }
                }
            )
            .frame(width: 300, height: 400)
            Text("Selected: \(selected?.name ?? "None")")
        }
    }
    static var previews: some View {
        DemoWrapper()
    }
} 
