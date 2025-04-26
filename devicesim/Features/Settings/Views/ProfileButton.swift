import SwiftUI

struct ProfileButton: View {
    let profileName: String
    let isActive: Bool
    let createdAt: Date
    let onLoad: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 5) {
            Text(profileName)
                .fontWeight(isActive ? .bold : .regular)
                .foregroundColor(isActive ? .accentColor : .primary)
            
            Text(dateFormatter.string(from: createdAt))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Button("Load") {
                    onLoad()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if profileName != "default" {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .frame(width: 120)
    }
} 