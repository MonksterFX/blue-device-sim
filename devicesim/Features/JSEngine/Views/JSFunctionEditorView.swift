import Inject
import SwiftUI

struct JSFunctionEditorView: View {
    @ObserveInjection var inject
    @Bindable var viewModel: JSFunctionsAdminViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("JS Function Editor")
                .font(.headline)

            Text("Description")
            InputField(value: $viewModel.description)
                .onChange(of: viewModel.description) { _, _ in
                    viewModel.changeDetection()
                }

            Text("Editor")
            CodeEditor(code: $viewModel.jsCode)
                .onChange(of: viewModel.jsCode) { _, _ in
                    viewModel.changeDetection()
                }

            HStack {
                Button("Save Preset") {
                    viewModel.saveCurrentPreset()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)

                Spacer()

                Button("Load Example") {
                    viewModel.loadExample()
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }

        }.enableInjection()
    }
}
