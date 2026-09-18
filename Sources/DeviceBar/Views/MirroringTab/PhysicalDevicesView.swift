import SwiftUI

public struct PhysicalDevicesView: View {
    @ObservedObject public var viewModel: AppViewModel
    @State private var recordingDuration: Int = 15
    @State private var isRecording: Bool = false

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Section Header
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Thiết Bị Thật (Physical Devices)")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        Text("Nhận diện tự động qua cổng USB hoặc Wi-Fi ADB / iOS Developer")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Button {
                        Task { await viewModel.refreshAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(5)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Quét lại thiết bị kết nối")
                }

                if viewModel.connectedDevices.isEmpty {
                    // Refined Empty State
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryGradient.opacity(0.12))
                                .frame(width: 56, height: 56)

                            Image(systemName: "cable.connector.slash")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(Color(hex: "3B82F6"))
                        }

                        VStack(spacing: 4) {
                            Text("Chưa phát hiện thiết bị cắm ngoài")
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))

                            Text("Cắm cáp USB hoặc kết nối cùng mạng Wi-Fi để bắt đầu.")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary)
                        }

                        // Tips Card
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "F59E0B"))
                                Text("Hướng dẫn kết nối:")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }

                            Text("• Android: Bật USB Debugging trong Developer Options.")
                                .font(.system(size: 10.5, design: .rounded))
                                .foregroundColor(.secondary)

                            Text("• iOS: Cắm cáp và chọn 'Tin cậy máy tính này' (Trust This Computer).")
                                .font(.system(size: 10.5, design: .rounded))
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                Text("• Công cụ chiếu màn hình:")
                                    .font(.system(size: 10.5, design: .rounded))
                                    .foregroundColor(.secondary)
                                Text("brew install scrcpy")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(Color(hex: "3B82F6"))
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.connectedDevices) { device in
                            DeviceCardItem(device: device, viewModel: viewModel, recordingDuration: recordingDuration)
                        }
                    }
                }

                Divider()
                    .opacity(0.4)

                // Bottom Utilities Card (scrcpy & libimobiledevice helper)
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: "3B82F6").opacity(0.12))
                                .frame(width: 28, height: 28)

                            Image(systemName: "terminal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "3B82F6"))
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Android Screen Mirroring (scrcpy)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                            Text("brew install scrcpy")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("brew install scrcpy", forType: .string)
                            viewModel.showStatus("Đã copy lệnh 'brew install scrcpy' vào Clipboard!")
                        } label: {
                            Text("Copy")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Divider().opacity(0.3)

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: "10B981").opacity(0.12))
                                .frame(width: 28, height: 28)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "10B981"))
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Chụp ảnh iPhone thật (idevicescreenshot)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                            Text("brew install libimobiledevice")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("brew install libimobiledevice", forType: .string)
                            viewModel.showStatus("Đã copy lệnh 'brew install libimobiledevice' vào Clipboard!")
                        } label: {
                            Text("Copy")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Individual Physical Device Card
private struct DeviceCardItem: View {
    let device: ConnectedDevice
    @ObservedObject var viewModel: AppViewModel
    let recordingDuration: Int

    @State private var isHovered: Bool = false
    @State private var isRecording: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Info
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(device.platform == .android ? Color(hex: "10B981").opacity(0.15) : Color(hex: "3B82F6").opacity(0.15))
                        .frame(width: 32, height: 32)

                    DeviceIconView(
                        type: device.platform == .android ? .android(name: device.name) : .ios(name: device.name),
                        isOnline: true,
                        size: 16
                    )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))

                    HStack(spacing: 6) {
                        Text(device.serial)
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))

                        HStack(spacing: 3) {
                            Image(systemName: device.connectionType.iconName)
                                .font(.system(size: 8.5))
                            Text(device.connectionType.rawValue)
                                .font(.system(size: 9.5, design: .rounded))
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                StatusBadge(isOnline: true, label: "Connected")
            }

            Divider()
                .opacity(0.3)

            // 1-Click Action Buttons
            HStack(spacing: 6) {
                if device.platform == .android {
                    // Mirroring button
                    Button {
                        Task { await viewModel.launchMirroring(device: device) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "display")
                                .font(.system(size: 10))
                            Text("Mirror")
                                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .help("Chiếu màn hình điện thoại lên Mac bằng scrcpy")
                }

                // Screenshot Menu
                Menu {
                    Button("Chụp vào Clipboard") {
                        Task { await viewModel.captureDeviceScreenshot(device: device, saveToDesktop: false) }
                    }
                    Button("Chụp & Lưu vào Desktop") {
                        Task { await viewModel.captureDeviceScreenshot(device: device, saveToDesktop: true) }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 9.5))
                        Text("Chụp ảnh")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    }
                }
                .menuStyle(.borderedButton)
                .controlSize(.small)

                // Video Record Button
                Button {
                    Task {
                        isRecording = true
                        await viewModel.recordDeviceVideo(device: device, durationSeconds: recordingDuration)
                        isRecording = false
                    }
                } label: {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(isRecording ? Color(hex: "F43F5E") : Color.secondary)
                            .frame(width: 5, height: 5)
                        Text(isRecording ? "Đang quay..." : "Quay video")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRecording)

                if device.platform == .android && device.connectionType == .usb {
                    // Wi-Fi ADB toggle
                    Button {
                        Task { await viewModel.enableWifiAdb(device: device) }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "wifi")
                                .font(.system(size: 9.5))
                            Text("Wi-Fi ADB")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Kích hoạt ADB qua mạng Wi-Fi để rút cáp ra vẫn debug được")
                }

                Spacer()
            }
        }
        .padding(10)
        .background(AppTheme.cardBackground(isHovered: isHovered))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
