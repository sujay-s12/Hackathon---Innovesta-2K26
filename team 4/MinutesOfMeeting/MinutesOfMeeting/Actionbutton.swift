import SwiftUI

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let isActive: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isActive ? .red : .primary)
                    .frame(width: 24)

                Text(label)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
