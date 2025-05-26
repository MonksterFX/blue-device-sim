import SwiftUI

/// A reusable code editor for JavaScript code, with monospaced font and no autoformatting.
/// Used for editing both read() and write() functions in a single editor.
struct JSCodeEditor: View {
    @Binding var code: String
    @State private var height: CGFloat = 200
    
    var placeholder: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomTextEditor(text: $code)
                .frame(height: height)
                .border(Color.gray.opacity(0.3))
            Rectangle()
                .frame(height: 12)
                .foregroundColor(.clear)
                .background(Color.gray.opacity(0.15))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newHeight = max(100, height + value.translation.height)
                            height = newHeight
                        }
                )
        }
    }
} 
