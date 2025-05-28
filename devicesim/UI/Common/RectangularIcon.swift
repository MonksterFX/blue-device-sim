import SwiftUI

struct RectangularIcon: View {
    var letter: String = "S"
    var backgroundColor: Color = .blue
    var textColor: Color = .white
    var width: CGFloat = 20
    var height: CGFloat = 20

    var body: some View {
        Text(letter)
            .font(.headline)
            .foregroundColor(textColor)
            .frame(width: width, height: height)
            .background(backgroundColor)
            .cornerRadius(2) // Rounded corners, adjust or remove for sharp corners
    }
}