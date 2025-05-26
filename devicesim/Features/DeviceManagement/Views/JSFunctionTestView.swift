import Inject
import SwiftUI

struct JSFunctionTestView: View {
    @ObserveInjection var inject
    @Bindable var viewModel: JSFunctionsAdminViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test JS Function")
                .font(.headline)

            Picker("Operation", selection: $viewModel.operation) {
                ForEach(JSFunctionsAdminViewModel.OperationType.allCases) { op in
                    Text(op.rawValue).tag(op)
                }
            }
            .pickerStyle(.segmented)
            .tint(.accentColor)

            if viewModel.operation == .write {
                TextField("Input value", text: $viewModel.testInput)
                    .textFieldStyle(.roundedBorder)
            }

            if viewModel.operation == .notify {

            }

            HStack {
                Button("Run Test") {
                    viewModel.runTest()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
                
                Button("Reset Context") {
                    viewModel.resetContext()
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Last Result")
                    .font(.subheadline)
                Text(viewModel.lastResult)
                    .font(.body)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            Spacer()
        }.enableInjection()
    }
}
