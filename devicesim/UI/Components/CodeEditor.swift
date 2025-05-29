import Inject
import SwiftUI

// TODO: HACK to work-around the smart quote issue
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            self.isAutomaticQuoteSubstitutionEnabled = false
        }
    }
}

struct CodeEditor: View {
    @Binding var code: String
    @ObserveInjection var inject

    var body: some View {
        VStack {
            TextEditor(text: $code)

                .frame(minHeight: 100)
                .padding(10)
                .background(Color(.textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            Spacer()
        }.enableInjection()
    }
}
