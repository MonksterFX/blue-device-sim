import Inject
import SwiftUI

struct ConvertionTypePicker: View {
    @Binding var selectedType: ConvertionTypes

    var body: some View {
        Picker("Convertion Type", selection: $selectedType) {
            Text("String").tag(ConvertionTypes.string)
            Text("Number").tag(ConvertionTypes.number)
            Text("Buffer").tag(ConvertionTypes.buffer)
        }
    }
}

struct JSFunctionTestView: View {
    @ObserveInjection var inject
    @Bindable var viewModel: JSFunctionsAdminViewModel
    @Bindable var testViewModel: JSFunctionsTestViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // MARK: - Test Header
            HStack{
                Text("Test JS Function")
                    .font(.headline)
                
                Spacer()
                
                Button("Run Test") {
                    viewModel.runTest()
                }
                .buttonStyle(.borderedProminent)
            }

            Picker("Operation", selection: $viewModel.operation) {
                ForEach(OperationType.allCases) { op in
                    Text(op.rawValue).tag(op)
                }
            }
            .pickerStyle(.segmented)
            .tint(.accentColor)

            // MARK: - Test Input

            if viewModel.operation == .write {
                TextField("Input value", text: $viewModel.testInput)
                    .textFieldStyle(.roundedBorder)
            }

            if viewModel.operation == .notify {
                Text("Currently not supported")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            // HStack {
            //     Button("Reset Context") {
            //         viewModel.resetContext()
            //     }
            //     .buttonStyle(.bordered)

            //     Button("Load Type Hint") {
            //         viewModel.loadTypeHint(key: "writeTypes.in")
            //     }
            //     .buttonStyle(.bordered)
            // }

            // VStack(alignment: .leading, spacing: 4) {
            //     Text("Input Type")
            //         .font(.subheadline)
            //     ConvertionTypePicker(selectedType: $viewModel.inputType)

            //     Text("Result Type")
            //         .font(.subheadline)
            //     ConvertionTypePicker(selectedType: $viewModel.resultType)
            // }
            // .pickerStyle(.segmented)
            // .tint(.accentColor)
            // .padding(.vertical, 4)

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
 
            JSTypeInputView(viewModel: viewModel)

            Spacer()

        }.enableInjection()
    }
}
