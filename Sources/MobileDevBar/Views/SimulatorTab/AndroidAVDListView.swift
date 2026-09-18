import SwiftUI

public struct AndroidAVDListView: View {
    @ObservedObject public var viewModel: AppViewModel

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            HStack(spacing: 6) {
                AndroidBugdroidIcon(color: Color(hex: "10B981"), size: 14)

                Text("Android Emulators (AVD)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))

                Spacer()

                Text("\(viewModel.filteredAVDs.count) máy ảo")
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundColor(.secondary)
            }

            if viewModel.filteredAVDs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "cube.box")
                        .font(.system(size: 26))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("Không tìm thấy Android AVD nào")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Text("Tạo thêm máy ảo trong Android Studio Device Manager")
                        .font(.system(size: 10.5, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                )
            } else {
                LazyVStack(spacing: 7) {
                    ForEach(viewModel.filteredAVDs) { avd in
                        AVDCardView(avd: avd, viewModel: viewModel)
                    }
                }
            }
        }
    }
}

// MARK: - Individual AVD Card View with Full Quick Controls
public struct AVDCardView: View {
    public let avd: AndroidAVD
    @ObservedObject public var viewModel: AppViewModel
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    @State private var isRecording: Bool = false
    @State private var deepLinkText: String = ""
    @State private var selectedPreset: LocationPreset = LocationPreset.defaults[0]
    @State private var selectedLocale: LocalePreset = LocalePreset.defaults[0]
    @State private var showTouches: Bool = false

    public init(avd: AndroidAVD, viewModel: AppViewModel) {
        self.avd = avd
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Row Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(avd.isRunning ? Color(hex: "10B981").opacity(0.15) : Color.primary.opacity(0.05))
                        .frame(width: 32, height: 32)

                    DeviceIconView(type: .android(name: avd.name), isOnline: avd.isRunning, size: 16)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(avd.name)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .lineLimit(1)

                    if let serial = avd.runningSerial {
                        HStack(spacing: 4) {
                            Text(serial)
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(Color(hex: "10B981"))
                            Text("• Running")
                                .font(.system(size: 9.5, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Android Virtual Device")
                            .font(.system(size: 9.5, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }

                Spacer()

                StatusBadge(
                    isOnline: avd.isRunning,
                    label: avd.isRunning ? "Running" : "Stopped"
                )

                // Power button
                Button {
                    Task {
                        if avd.isRunning {
                            await viewModel.killAVD(avd)
                        } else {
                            await viewModel.startAVD(avd)
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(avd.isRunning ? Color(hex: "F97316").opacity(0.15) : Color(hex: "10B981").opacity(0.15))
                            .frame(width: 26, height: 26)

                        Image(systemName: avd.isRunning ? "power" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(avd.isRunning ? Color(hex: "F97316") : Color(hex: "10B981"))
                    }
                }
                .buttonStyle(.plain)
                .help(avd.isRunning ? "Tắt AVD" : "Khởi động AVD")

                if avd.isRunning {
                    // Expand/Collapse Chevron Button
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
                    .help("Mở công cụ điều khiển nhanh AVD")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            // Stopped state secondary buttons
            if !avd.isRunning {
                Divider()
                    .opacity(0.3)
                    .padding(.horizontal, 8)

                HStack(spacing: 8) {
                    Button {
                        Task { await viewModel.startAVD(avd, coldBoot: true) }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "snowflake")
                                .font(.system(size: 9.5))
                            Text("Cold Boot")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .help("Khởi động không tải snapshot")

                    Button(role: .destructive) {
                        Task { await viewModel.startAVD(avd, wipeData: true) }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "trash")
                                .font(.system(size: 9.5))
                            Text("Wipe Data")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .help("Xóa sạch data và khởi động lại")

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }

            // Expanded Quick Controls Panel for Running AVD
            if avd.isRunning && isExpanded {
                Divider()
                    .opacity(0.4)
                    .padding(.horizontal, 8)

                VStack(alignment: .leading, spacing: 8) {
                    // Row 1: Appearance & Developer Tools
                    HStack(spacing: 8) {
                        // Dark / Light Theme
                        HStack(spacing: 3) {
                            Button {
                                Task { await viewModel.toggleAndroidAppearance(avd: avd, dark: true) }
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
                                Task { await viewModel.toggleAndroidAppearance(avd: avd, dark: false) }
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

                        // Show Touches & Dev Settings
                        HStack(spacing: 6) {
                            Button {
                                showTouches.toggle()
                                Task { await viewModel.toggleAndroidTouches(avd: avd, enabled: showTouches) }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: showTouches ? "hand.point.up.fill" : "hand.point.up")
                                        .font(.system(size: 9.5))
                                    Text("Show Touches")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(showTouches ? Color(hex: "10B981") : .secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3.5)
                                .background(showTouches ? Color(hex: "10B981").opacity(0.12) : Color.primary.opacity(0.05))
                                .cornerRadius(5)
                            }
                            .buttonStyle(.plain)

                            Button {
                                Task { await viewModel.openAndroidDevSettings(avd: avd) }
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 10))
                                    .padding(4)
                                    .background(Color.primary.opacity(0.05))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .help("Mở Developer Settings")
                        }
                    }

                    // Row 2: Mock Location
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
                            Task { await viewModel.setAndroidMockLocation(avd: avd, preset: selectedPreset) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    // Row 3: Deep Link Opener
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
                            Task { await viewModel.openAndroidDeepLink(avd: avd, url: deepLinkText) }
                        } label: {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(deepLinkText.trimmingCharacters(in: .whitespaces).isEmpty)
                        .help("Bắn URL scheme vào Android")
                    }

                    Divider()
                        .opacity(0.3)

                    // Row 4: Mirror, Screenshot, Screen Record Actions
                    HStack(spacing: 6) {
                        // Mirroring Button
                        Button {
                            Task {
                                if let serial = avd.runningSerial {
                                    try? await AndroidService.shared.launchMirroring(serial: serial)
                                }
                            }
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

                        // Screenshot Menu
                        Menu {
                            Button("Chụp vào Clipboard") {
                                Task {
                                    if let serial = avd.runningSerial {
                                        _ = try? await AndroidService.shared.captureScreenshot(serial: serial, saveToDesktop: false)
                                    }
                                }
                            }
                            Button("Chụp & Lưu vào Desktop") {
                                Task {
                                    if let serial = avd.runningSerial {
                                        _ = try? await AndroidService.shared.captureScreenshot(serial: serial, saveToDesktop: true)
                                    }
                                }
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
                                if let serial = avd.runningSerial {
                                    isRecording = true
                                    _ = try? await AndroidService.shared.startScreenRecord(serial: serial, durationSeconds: 10)
                                    isRecording = false
                                }
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

                        Spacer()
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
