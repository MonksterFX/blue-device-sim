import SwiftUI

struct PresetsListView: View {
    @Bindable var viewModel: JSFunctionsAdminViewModel
    
    var body: some View {
         EditableListView(
             items: viewModel.presets,
             getName: { preset in preset.name },
             onAdd: { name in viewModel.createNewPreset(name)},
             onDelete: { preset in viewModel.deletePreset(preset)},
             onSelect: { preset in viewModel.selectPreset(preset.id)},
             onRename: { preset, name in viewModel.renamePreset(name)}
        )
    }
} 
