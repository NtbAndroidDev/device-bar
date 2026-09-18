import SwiftUI

// MARK: - Android Bugdroid Head Icon (Vector Canvas)
public struct AndroidBugdroidIcon: View {
    public var color: Color
    public var size: CGFloat

    public init(color: Color = Color(hex: "10B981"), size: CGFloat = 18) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height

            // 1. Antennas (Hai râu ăng-ten của chú robot Android)
            var leftAntenna = Path()
            leftAntenna.move(to: CGPoint(x: w * 0.33, y: h * 0.32))
            leftAntenna.addLine(to: CGPoint(x: w * 0.20, y: h * 0.10))
            context.stroke(
                leftAntenna,
                with: .color(color),
                style: StrokeStyle(lineWidth: w * 0.085, lineCap: .round)
            )

            var rightAntenna = Path()
            rightAntenna.move(to: CGPoint(x: w * 0.67, y: h * 0.32))
            rightAntenna.addLine(to: CGPoint(x: w * 0.80, y: h * 0.10))
            context.stroke(
                rightAntenna,
                with: .color(color),
                style: StrokeStyle(lineWidth: w * 0.085, lineCap: .round)
            )

            // 2. Head Dome (Đầu bán nguyệt tròn đặc trưng)
            var head = Path()
            head.addArc(
                center: CGPoint(x: w * 0.50, y: h * 0.80),
                radius: w * 0.40,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            head.closeSubpath()
            context.fill(head, with: .color(color))

            // 3. Eyes (Hai mắt tròn màu trắng hoặc nền tương phản)
            let eyeR = w * 0.045
            let eyeY = h * 0.60
            let leftEye = Path(ellipseIn: CGRect(
                x: w * 0.36 - eyeR,
                y: eyeY - eyeR,
                width: eyeR * 2,
                height: eyeR * 2
            ))
            let rightEye = Path(ellipseIn: CGRect(
                x: w * 0.64 - eyeR,
                y: eyeY - eyeR,
                width: eyeR * 2,
                height: eyeR * 2
            ))
            context.fill(leftEye, with: .color(Color(NSColor.windowBackgroundColor)))
            context.fill(rightEye, with: .color(Color(NSColor.windowBackgroundColor)))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Smart Device Icon View
public struct DeviceIconView: View {
    public enum DeviceType {
        case ios(name: String)
        case android(name: String)
    }

    public let type: DeviceType
    public let isOnline: Bool
    public var size: CGFloat

    public init(type: DeviceType, isOnline: Bool, size: CGFloat = 16) {
        self.type = type
        self.isOnline = isOnline
        self.size = size
    }

    public var body: some View {
        switch type {
        case .ios(let name):
            if name.localizedCaseInsensitiveContains("iPad") {
                Image(systemName: "ipad")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundColor(isOnline ? Color(hex: "3B82F6") : .secondary)
            } else if name.localizedCaseInsensitiveContains("Watch") {
                Image(systemName: "applewatch")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundColor(isOnline ? Color(hex: "3B82F6") : .secondary)
            } else {
                Image(systemName: "iphone")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundColor(isOnline ? Color(hex: "3B82F6") : .secondary)
            }

        case .android(let name):
            if name.localizedCaseInsensitiveContains("Fold") {
                Image(systemName: "square.split.2x1")
                    .font(.system(size: size - 1, weight: .semibold))
                    .foregroundColor(isOnline ? Color(hex: "10B981") : .secondary)
            } else if name.localizedCaseInsensitiveContains("Tablet") {
                Image(systemName: "ipad.landscape")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundColor(isOnline ? Color(hex: "10B981") : .secondary)
            } else {
                AndroidBugdroidIcon(
                    color: isOnline ? Color(hex: "10B981") : .secondary.opacity(0.6),
                    size: size + 2
                )
            }
        }
    }
}
