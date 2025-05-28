import Inject
import SwiftUI

struct InputField: View {
    @Binding var value: String
    var label: String?
    @ObserveInjection var inject

    var body: some View {
        HStack() {
            if let label = label {
                Text(label)
                    .font(.headline)
            }
            
                    TextField("Enter text", text: $value)
            .textFieldStyle(.plain)
            .padding(10)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .enableInjection()
    }
}
