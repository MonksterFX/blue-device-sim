import SwiftUI

struct JSFunctionsPresetsListView: View {
    @Bindable var viewModel: JSFunctionsAdminViewModel
    
    var body: some View {
         EditableListView(
             items: viewModel.presets,
             selectedItem: viewModel.selectedPreset,
             getName: { preset in preset.name },
             onAdd: { name in viewModel.createNewPreset(name)},
             onDelete: { preset in viewModel.deletePreset(preset)},
             onSelect: { preset in viewModel.selectPreset(preset)},
             onRename: { preset, name in viewModel.renamePreset(name)}
        )
    }
} 
