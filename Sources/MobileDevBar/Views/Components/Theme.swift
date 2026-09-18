import SwiftUI
import AppKit

// MARK: - Design System & Visual Tokens
public enum AppTheme {
    // MARK: - Colors & Gradients
    public static let primaryGradient = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let emeraldGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let roseGradient = LinearGradient(
        colors: [Color(hex: "F43F5E"), Color(hex: "E11D48")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let amberGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Surfaces
    public static func cardBackground(isHovered: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.75 : 0.45))
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.22 : 0.12),
                                Color.white.opacity(isHovered ? 0.08 : 0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.12 : 0.04), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
    }

    public static func innerGroupBackground() -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

// MARK: - Color Hex Extension
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Tactile Scale Button Style (Micro-interaction)
public struct ScaleButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

