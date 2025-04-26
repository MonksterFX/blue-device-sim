import SwiftUI

struct ProfileButton: View {
    let profileName: String
    let isActive: Bool
    let createdAt: Date
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(profileName)
                        .fontWeight(isActive ? .bold : .regular)
                    Text(createdAt.formatted(.dateTime.day().month().year()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                
                if !isActive && profileName != "default" {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
            }
        }
        .padding(.vertical, 8)
        .background(isActive ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .onTapGesture(perform: onSelect)
    }
} 