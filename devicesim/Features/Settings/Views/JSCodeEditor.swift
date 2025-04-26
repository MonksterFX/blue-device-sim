import SwiftUI

/// A reusable code editor for JavaScript code, with monospaced font and no autoformatting.
/// Used for editing both read() and write() functions in a single editor.
struct JSCodeEditor: View {
    @Binding var code: String
    var placeholder: String = ""
    var height: CGFloat = 200
    var body: some View {
        TextEditor(text: $code)
            .font(.system(.body, design: .monospaced))
            .frame(height: height)
            .border(Color.gray.opacity(0.3))
            .disableAutocorrection(true)
    }
} 
