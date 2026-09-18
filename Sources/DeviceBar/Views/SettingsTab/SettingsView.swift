import SwiftUI
import AppKit
import ServiceManagement

public struct SettingsView: View {
    @ObservedObject public var viewModel: AppViewModel
    @ObservedObject private var langManager = LanguageManager.shared

    @AppStorage("auto_refresh_interval") private var refreshInterval: Double = 3.0
    @AppStorage("network_inspector_buffer") private var networkBufferSize: Int = 100

    @State private var xcodeInstalled: Bool = true
    @State private var adbPath: String = "Checking..."
    @State private var adbInstalled: Bool = false
    @State private var scrcpyInstalled: Bool = false
    @State private var isCheckingEnv: Bool = false

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - 1. Language Selector
                languageSection

                // MARK: - 2. General & macOS Integration
                generalSection

                // MARK: - 3. Developer Tooling Environment
                environmentSection

                // MARK: - 4. Network Inspector Configuration
                networkInspectorSection

                // MARK: - 5. About DeviceBar
                aboutSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .task {
            await checkToolingEnvironment()
        }
    }

    // MARK: - 1. Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "3B82F6"))
                Text(loc("settings_language"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { lang in
                    let isSelected = langManager.currentLanguage == lang
                    Button {
                        langManager.setLanguage(lang)
                    } label: {
                        HStack(spacing: 6) {
                            Text(lang.flag)
                                .font(.system(size: 14))
                            Text(lang.displayName)
                                .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium, design: .rounded))
                        }
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(AppTheme.primaryGradient)
                                        .shadow(color: Color(hex: "3B82F6").opacity(0.3), radius: 4, y: 2)
                                } else {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.primary.opacity(0.04))
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.08), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    // MARK: - 2. General Section
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "macwindow")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "10B981"))
                Text(loc("settings_general"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer()
            }

            // Launch at login toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("settings_launch_at_login"))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    Text(loc("settings_launch_at_login_desc"))
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.isLaunchAtLogin },
                    set: { _ in viewModel.toggleLaunchAtLogin() }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
            }

            Divider().opacity(0.3)

            // Auto Refresh Picker
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(loc("settings_auto_refresh"))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    Spacer()
                    Picker("", selection: $refreshInterval) {
                        Text(loc("refresh_fast")).tag(1.5)
                        Text(loc("refresh_normal")).tag(3.0)
                        Text(loc("refresh_slow")).tag(6.0)
                        Text(loc("refresh_manual")).tag(0.0)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                    .onChange(of: refreshInterval) { newValue in
                        viewModel.updateRefreshInterval(newValue)
                    }
                }
                Text(loc("settings_auto_refresh_desc"))
                    .font(.system(size: 9.5, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Divider().opacity(0.3)

            // Install to Applications
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("install_app"))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    Text(loc("install_app_desc"))
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        let sourcePath = "/Users/Shared/Data/source/macos/MobileDevBar/DeviceBar.app"
                        _ = try? await ShellService.shared.run("cp -R \"\(sourcePath)\" /Applications/")
                        viewModel.showStatus(langManager.currentLanguage == .vietnamese ? "Đã cài đặt DeviceBar vào /Applications!" : "Installed DeviceBar into /Applications!")
                    }
                } label: {
                    Text(loc("install_app"))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    // MARK: - 3. Environment Section
    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "F59E0B"))
                Text(loc("settings_environment"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer()

                Button {
                    Task { await checkToolingEnvironment() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Recheck environment tools")
            }

            // Xcode Tools
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(loc("xcode_tools"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                    Text("xcrun simctl")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Spacer()
                statusBadge(isOk: xcodeInstalled)
            }

            Divider().opacity(0.3)

            // Android ADB
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(loc("android_sdk_adb"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                    Text(adbPath)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                statusBadge(isOk: adbInstalled)
            }

            Divider().opacity(0.3)

            // Scrcpy
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(loc("scrcpy_tool"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                    Text(loc("install_guide_scrcpy"))
                        .font(.system(size: 9, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
                statusBadge(isOk: scrcpyInstalled)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    // MARK: - 4. Network Inspector Config
    private var networkInspectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "8B5CF6"))
                Text(loc("settings_network_inspector"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("buffer_size"))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    Text(loc("buffer_size_desc"))
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Picker("", selection: $networkBufferSize) {
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                    Text("500").tag(500)
                }
                .pickerStyle(.menu)
                .frame(width: 80)
            }

            Divider().opacity(0.3)

            HStack {
                Button {
                    DebugWindowManager.shared.openNetworkInspector()
                } label: {
                    Label(loc("open_network_inspector"), systemImage: "arrow.up.right.square")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(hex: "3B82F6"))

                Spacer()

                Button {
                    DebugWindowManager.shared.openCrashInspector()
                } label: {
                    Label(loc("open_crash_detective"), systemImage: "shield.lefthalf.filled")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(hex: "EF4444"))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    // MARK: - 5. About Section
    private var aboutSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.primaryGradient)
                        .frame(width: 32, height: 32)
                        .shadow(color: Color(hex: "3B82F6").opacity(0.3), radius: 4, y: 2)

                    Image(systemName: "macbook.and.iphone")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("DeviceBar")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Text("v1.2.0")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Text(loc("license"))
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    if let url = URL(string: "https://github.com/NtbAndroidDev/device-bar") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                        Text("GitHub")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.3)

            // Quit Button
            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .bold))
                    Text(loc("quit_app"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(Color(hex: "EF4444"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(hex: "EF4444").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Helper UI
    private func statusBadge(isOk: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOk ? Color(hex: "10B981") : Color(hex: "EF4444"))
                .frame(width: 5, height: 5)
            Text(isOk ? loc("status_installed") : loc("status_not_found"))
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .foregroundColor(isOk ? Color(hex: "10B981") : Color(hex: "EF4444"))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(isOk ? Color(hex: "10B981").opacity(0.1) : Color(hex: "EF4444").opacity(0.1))
        .clipShape(Capsule())
    }

    private func checkToolingEnvironment() async {
        isCheckingEnv = true
        defer { isCheckingEnv = false }

        // 1. Xcode simctl
        do {
            let res = try await ShellService.shared.run("which xcrun")
            xcodeInstalled = !res.isEmpty
        } catch {
            xcodeInstalled = false
        }

        // 2. Android ADB
        do {
            let path = try await ShellService.shared.run("which adb")
            if !path.isEmpty {
                adbPath = path
                adbInstalled = true
            } else {
                adbPath = "Not found in PATH"
                adbInstalled = false
            }
        } catch {
            adbPath = "Not configured"
            adbInstalled = false
        }

        // 3. Scrcpy
        scrcpyInstalled = await ShellService.shared.isCommandAvailable("scrcpy")
    }
}
