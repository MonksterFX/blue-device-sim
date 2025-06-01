import Foundation

@Observable
class JSFunctionsTestViewModel {

    var viewModel: JSFunctionsAdminViewModel

    var inputTypes: [TypedValue] = []
    var outputTypes: [TypedValue] = []

    var inputValues: [String] = []
    var outputValues: [String] = []

    var singleInput: String = ""
    var singleOutput: String = ""

    var isSimpleTest: Bool = false

    init(viewModel: JSFunctionsAdminViewModel) {
        self.viewModel = viewModel
    }

    func onInputTypesChanged(inputTypes: [TypedValue]) {
        self.inputTypes = inputTypes
    }

    func onOutputTypesChanged(outputTypes: [TypedValue]) {
        self.outputTypes = outputTypes
    }

    func onInputValuesChanged(inputValues: [String]) {
        self.inputValues = inputValues
    }

    func onOutputValuesChanged(outputValues: [String]) {
        self.outputValues = outputValues
    }


}