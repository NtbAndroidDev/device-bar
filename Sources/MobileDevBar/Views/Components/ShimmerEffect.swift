import SwiftUI

// MARK: - Premium Shimmer Loading Effect
public struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 1.5)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2.5))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

public extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Card Placeholder
public struct SkeletonCardView: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 140, height: 12)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 80, height: 9)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 60, height: 18)

                Circle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 24, height: 24)
            }
        }
        .padding(10)
        .background(AppTheme.cardBackground())
        .shimmering()
    }
}
