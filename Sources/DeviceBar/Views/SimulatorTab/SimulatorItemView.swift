import SwiftUI

public struct SimulatorItemView: View {
    public let device: SimulatorDevice
    @ObservedObject public var viewModel: AppViewModel

    @State private var isExpanded: Bool = false
    @State private var isHovered: Bool = false
    @State private var deepLinkText: String = ""
    @State private var selectedPreset: LocationPreset = LocationPreset.defaults[0]
    @State private var selectedLocale: LocalePreset = LocalePreset.defaults[0]
    @State private var isRecordingVideo: Bool = false

    public init(device: SimulatorDevice, viewModel: AppViewModel) {
        self.device = device
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Row Header
            HStack(spacing: 10) {
                // Device Icon in Soft Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(device.state.isBooted ? Color(hex: "3B82F6").opacity(0.15) : Color.primary.opacity(0.05))
                        .frame(width: 32, height: 32)

                    DeviceIconView(type: .ios(name: device.name), isOnline: device.state.isBooted, size: 16)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(device.name)
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .lineLimit(1)

                        Text(device.osVersion)
                            .font(.system(size: 9.5, weight: .medium, design: .rounded))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.primary.opacity(0.06))
                            .foregroundColor(.secondary)
                            .clipShape(Capsule())
                    }

                    Text(device.udid)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                // Status Badge
                StatusBadge(
                    isOnline: device.state.isBooted,
                    label: device.state.rawValue
                )

                // Power Toggle Button
                Button {
                    Task {
                        if device.state.isBooted {
                            await viewModel.shutdownSimulator(device)
                        } else {
                            await viewModel.bootSimulator(device)
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(device.state.isBooted ? Color(hex: "F97316").opacity(0.15) : Color(hex: "10B981").opacity(0.15))
                            .frame(width: 26, height: 26)

                        Image(systemName: device.state.isBooted ? "power" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(device.state.isBooted ? Color(hex: "F97316") : Color(hex: "10B981"))
                    }
                }
                .buttonStyle(.plain)
                .help(device.state.isBooted ? "Tắt Simulator" : "Khởi động Simulator")

                // Expand Settings Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 22, height: 22)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Mở công cụ điều khiển nhanh")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            // Expanded Quick Controls Panel
            if isExpanded {
                Divider()
                    .opacity(0.4)
                    .padding(.horizontal, 8)

                VStack(alignment: .leading, spacing: 8) {
                    if device.state.isBooted {
                        // Section 1: Appearance & Biometrics
                        HStack(spacing: 8) {
                            // Dark / Light Theme
                            HStack(spacing: 3) {
                                Button {
                                    Task { await viewModel.toggleAppearance(device: device, dark: true) }
                                } label: {
                                    HStack(spacing: 3) {
                                        Text("🌙")
                                        Text("Dark")
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3.5)
                                    .background(Color.primary.opacity(0.06))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    Task { await viewModel.toggleAppearance(device: device, dark: false) }
                                } label: {
                                    HStack(spacing: 3) {
                                        Text("☀️")
                                        Text("Light")
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3.5)
                                    .background(Color.primary.opacity(0.06))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            // FaceID Match / Fail
                            HStack(spacing: 4) {
                                Text("FaceID:")
                                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)

                                Button {
                                    Task { await viewModel.triggerBiometric(device: device, match: true) }
                                } label: {
                                    HStack(spacing: 2) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                        Text("Pass")
                                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(Color(hex: "10B981"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3.5)
                                    .background(Color(hex: "10B981").opacity(0.12))
                                    .cornerRadius(5)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    Task { await viewModel.triggerBiometric(device: device, match: false) }
                                } label: {
                                    HStack(spacing: 2) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                        Text("Fail")
                                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(Color(hex: "F43F5E"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3.5)
                                    .background(Color(hex: "F43F5E").opacity(0.12))
                                    .cornerRadius(5)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Section 2: Mock Location
                        HStack(spacing: 6) {
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 10.5))
                                .foregroundColor(Color(hex: "3B82F6"))

                            Text("GPS:")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)

                            Picker("", selection: $selectedPreset) {
                                ForEach(LocationPreset.defaults) { preset in
                                    Text(preset.name).tag(preset)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .controlSize(.small)

                            Button("Đặt") {
                                Task { await viewModel.setMockLocation(device: device, preset: selectedPreset) }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }

                        // Section 3: Locale & Language
                        HStack(spacing: 6) {
                            Image(systemName: "globe.asia.australia.fill")
                                .font(.system(size: 10.5))
                                .foregroundColor(Color(hex: "10B981"))

                            Text("Ngôn ngữ:")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)

                            Picker("", selection: $selectedLocale) {
                                ForEach(LocalePreset.defaults) { loc in
                                    Text(loc.name).tag(loc)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .controlSize(.small)

                            Button("Áp dụng") {
                                Task { await viewModel.changeSimulatorLocale(device: device, preset: selectedLocale) }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        // Section 4: Deep Link Opener
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.system(size: 10.5))
                                .foregroundColor(Color(hex: "8B5CF6"))

                            TextField("myapp://path/order?id=123", text: $deepLinkText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(6)

                            Button {
                                Task { await viewModel.openDeepLink(device: device, url: deepLinkText) }
                            } label: {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(deepLinkText.trimmingCharacters(in: .whitespaces).isEmpty)
                            .help("Bắn URL scheme vào simulator")
                        }

                        Divider()
                            .opacity(0.3)

                        // Section 5: Media Capture & Wipe Actions
                        HStack(spacing: 8) {
                            // Screenshot Dropdown Menu
                            Menu {
                                Button("Chụp không nền (Alpha) ➔ Clipboard") {
                                    Task { await viewModel.captureSimScreenshot(device: device, mask: .alpha, saveToDesktop: false) }
                                }
                                Button("Chụp không nền (Alpha) ➔ Lưu Desktop") {
                                    Task { await viewModel.captureSimScreenshot(device: device, mask: .alpha, saveToDesktop: true) }
                                }
                                Button("Chụp ảnh chữ nhật (Ignored) ➔ Clipboard") {
                                    Task { await viewModel.captureSimScreenshot(device: device, mask: .ignored, saveToDesktop: false) }
                                }
                            } label: {
                                Label("Chụp màn hình", systemImage: "camera.fill")
                                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            }
                            .menuStyle(.borderedButton)
                            .controlSize(.small)

                            // Video Record
                            Button {
                                isRecordingVideo = true
                                Task {
                                    await viewModel.recordSimVideo(device: device, durationSeconds: 10)
                                    isRecordingVideo = false
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(isRecordingVideo ? Color(hex: "F43F5E") : Color.secondary)
                                        .frame(width: 6, height: 6)
                                    Text(isRecordingVideo ? "Đang quay 10s..." : "Quay Video")
                                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(isRecordingVideo)

                            // Advanced Tools Menu
                            Menu {
                                Section("Debugging & API") {
                                    Button {
                                        DebugWindowManager.shared.openNetworkInspector(
                                            deviceName: device.name,
                                            serial: device.udid,
                                            isAndroid: false
                                        )
                                    } label: {
                                        Label("Network & API Inspector (cURL)", systemImage: "network")
                                    }

                                    Button {
                                        DebugWindowManager.shared.openCrashInspector(
                                            deviceName: device.name,
                                            serial: device.udid,
                                            isAndroid: false
                                        )
                                    } label: {
                                        Label("Soi lỗi Crash văng app (Crash Detective)", systemImage: "ladybug.fill")
                                    }
                                }

                                Section("Files & Sandbox") {
                                    Button("Mở thư mục Data trong Finder") {
                                        viewModel.openSimulatorDataFolder(device: device)
                                    }
                                    Button("Mở Sandbox App (Documents/Cache)...") {
                                        viewModel.promptAndOpenAppContainer(device: device)
                                    }
                                    Button("Thêm ảnh/video từ Mac...") {
                                        Task { await viewModel.pickAndAddMediaToSimulator(device: device) }
                                    }
                                    Button("Thêm ảnh mẫu Gradient vào Photos") {
                                        Task { await viewModel.addSamplePhoto(device: device) }
                                    }
                                    Button("Cài đặt file .app vào Simulator...") {
                                        Task { await viewModel.pickAndInstallAppToSimulator(device: device) }
                                    }
                                }

                                Section("Testing & Controls") {
                                    Button("Bắn Push Notification test...") {
                                        viewModel.promptAndSendTestPush(device: device)
                                    }
                                    Button("Lắc máy (Shake / Mở Dev Menu)") {
                                        Task { await viewModel.triggerSimulatorShake(device: device) }
                                    }
                                    Button("Reset toàn bộ quyền riêng tư (Privacy)") {
                                        Task { await viewModel.resetSimulatorPrivacy(device: device) }
                                    }
                                }

                                Section("Clipboard") {
                                    Button("Paste Clipboard Mac sang Simulator") {
                                        Task { await viewModel.syncClipboard(device: device) }
                                    }
                                    Button("Copy Clipboard Simulator về Mac") {
                                        Task { await viewModel.syncClipboardFromSimulator(device: device) }
                                    }
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                        .font(.system(size: 9.5))
                                    Text("Tiện ích")
                                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                }
                            }
                            .menuStyle(.borderedButton)
                            .controlSize(.small)
                            .help("Tiện ích nâng cao: Sandbox, Push Test, Shake, Cài App, Thêm ảnh")

                            Spacer()

                            // Wipe Data
                            Button(role: .destructive) {
                                viewModel.promptAndEraseSimulator(device)
                            } label: {
                                Label("Wipe", systemImage: "trash")
                                    .font(.system(size: 10.5, design: .rounded))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Xóa sạch data và cache của Simulator này")

                        }
                    } else {
                        // Shutdown State Banner
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 11))
                            Text("Simulator đang tắt. Khởi động để kích hoạt FaceID, Mock GPS, Deep Link.")
                                .font(.system(size: 10.5, design: .rounded))
                                .foregroundColor(.secondary)

                            Spacer()

                            Button(role: .destructive) {
                                viewModel.promptAndEraseSimulator(device)
                            } label: {
                                Label("Wipe Data", systemImage: "trash")
                                    .font(.system(size: 10.5, design: .rounded))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(10)
                .background(Color.primary.opacity(0.02))
            }
        }
        .background(AppTheme.cardBackground(isHovered: isHovered))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
