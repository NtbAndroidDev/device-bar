import SwiftUI

public struct StatusBadge: View {
    public let isOnline: Bool
    public let label: String

    public init(isOnline: Bool, label: String) {
        self.isOnline = isOnline
        self.label = label
    }

    public var body: some View {
        HStack(spacing: 5) {
            ZStack {
                if isOnline {
                    Circle()
                        .fill(Color(hex: "10B981").opacity(0.35))
                        .frame(width: 10, height: 10)
                        .blur(radius: 2)
                }
                Circle()
                    .fill(isOnline ? Color(hex: "10B981") : Color.gray.opacity(0.5))
                    .frame(width: 6, height: 6)
            }

            Text(label)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundColor(isOnline ? Color(hex: "10B981") : .secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isOnline ? Color(hex: "10B981").opacity(0.12) : Color.primary.opacity(0.06))
        )
        .overlay(
            Capsule()
                .strokeBorder(isOnline ? Color(hex: "10B981").opacity(0.25) : Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

