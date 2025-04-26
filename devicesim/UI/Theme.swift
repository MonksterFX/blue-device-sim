import SwiftUI
import AppKit

/// Manages app-wide styling and design constants
enum Theme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let background = Color(NSColor.windowBackgroundColor)
        static let text = Color(NSColor.textColor)
        static let error = Color.red
        static let success = Color.green
    }
    
    // MARK: - Typography
    enum Typography {
        static let titleFont = Font.title
        static let headlineFont = Font.headline
        static let bodyFont = Font.body
        static let captionFont = Font.caption
    }
    
    // MARK: - Layout
    enum Layout {
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let cornerRadius: CGFloat = 12
    }
    
    // MARK: - Animation
    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
}

// MARK: - View Extensions
extension View {
    func standardPadding() -> some View {
        padding(Theme.Layout.standardPadding)
    }
    
    func primaryBackground() -> some View {
        background(Theme.Colors.background)
    }
} 
