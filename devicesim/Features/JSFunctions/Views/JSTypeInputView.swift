import SwiftUI

struct JSTypeInputView: View {
    @Bindable var viewModel: JSFunctionsAdminViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.parsedInputTypes, id: \.id) { type in
                HStack {
                    Text(type.type.rawValue)
                        .frame(width: 100, alignment: .leading)
                    if type.type == .string && type.stringLength != nil {
                        Text("(\(type.stringLength!))")
                            .foregroundColor(.gray)
                    }
                    TextField("Enter \(type.type.rawValue)", text: Binding(
                        get: { type.value },
                        set: { type.value = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        .padding()
    }
}
