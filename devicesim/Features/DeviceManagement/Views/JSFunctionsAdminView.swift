import SwiftUI
import Inject

// MARK: - Main View
struct JSFunctionsAdminView: View {
    @ObserveInjection var inject
    // main state
    @State private var viewModel = JSFunctionsAdminViewModel()
    
    var body: some View {      
        VStack{
            HStack(spacing: 0) {

                JSFunctionsPresetsListView(viewModel: viewModel)
                    .frame(width: 200)
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .border(Color.gray.opacity(0.2), width: 1)

                JSFunctionEditorView(viewModel: viewModel)
                    .frame(minWidth: 350, maxWidth: .infinity)
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .border(Color.gray.opacity(0.2), width: 1)

                JSFunctionTestView(viewModel: viewModel)
                    .frame(width: 320)
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    
            }
            .frame(minHeight: 400)
            .alert("Invalid Preset Name", isPresented: $viewModel.showInvalidNameAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text("Preset names may only contain letters, '-' and '_'.")
            })
            .alert("New Preset", isPresented: $viewModel.showNewPresetAlert, actions: {
                TextField("Preset Name", text: $viewModel.newPresetName)
                Button("Create") {
                    viewModel.createNewPreset(viewModel.newPresetName)
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text("Enter a name for the new preset.")
            })
            JSFunctionLog(viewModel: viewModel)
        }.enableInjection()
    }

}

// MARK: - Preview
// struct JSFunctionsAdminView_Previews: PreviewProvider {
//     static var previews: some View {
//         JSFunctionsAdminView(viewModel: JSFunctionsAdminViewModel)
//             .frame(width: 900, height: 500)
//     }
// } 
