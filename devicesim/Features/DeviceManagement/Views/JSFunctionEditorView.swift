import SwiftUI

struct JSFunctionEditorView: View {
    @Bindable var viewModel: JSFunctionsAdminViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("JS Function Editor")
                .font(.headline)
            Text("Description")
            TextField("Description", text: $viewModel.description, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            Text("Editor")
            JSCodeEditor(code: $viewModel.jsCode)
                .frame(minHeight: 250)
            Button("Save Preset") {
                viewModel.saveCurrentPreset()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            Spacer()
        }
    }
}


