import SwiftUI
import AppKit

public struct QuickToolsView: View {
    @ObservedObject public var viewModel: AppViewModel
    @State private var localIP: String = "Đang kiểm tra..."
    @State private var isCopiedIP: Bool = false
    @State private var isRestartingADB: Bool = false
    @State private var isCleaningAll: Bool = false

    // Real-time Storage Cleaner States
    @State private var derivedDataSize: String = "..."
    @State private var gradleCacheSize: String = "..."
    @State private var deviceSupportSize: String = "..."
    @State private var packageCacheSize: String = "..."
    @State private var simLogsSize: String = "..."
    @State private var archivesSize: String = "..."

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // MARK: - 1. Network Hub (LAN IP Widget)
                networkHub

                // MARK: - 2. Smart Developer Storage Cleaner Hub
                storageCleanerHub

                // MARK: - 3. Quick Media Access
                mediaAccessHub

                // MARK: - 4. Emergency & Reset
                emergencyResetHub
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .task {
            await fetchLocalIP()
            await calculateAllSizes()
        }
    }

    // MARK: - 1. Network Hub
    private var networkHub: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "wifi")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "3B82F6"))

                Text("Địa Chỉ IP Nội Bộ (LAN IP)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))

                Spacer()

                Text("Base URL Tester")
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image(systemName: "network")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "3B82F6"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(localIP)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    Text("Dùng địa chỉ này để gọi backend từ điện thoại thật")
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(localIP, forType: .string)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCopiedIP = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopiedIP = false
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopiedIP ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10, weight: .bold))
                        Text(isCopiedIP ? "Đã copy!" : "Copy IP")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(isCopiedIP ? Color(hex: "10B981") : .primary)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(10)
            .background(AppTheme.cardBackground())
        }
    }

    // MARK: - 2. Smart Storage Cleaner Hub
    private var storageCleanerHub: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "F59E0B"))

                Text("Dọn Dẹp Bộ Nhớ Developer (Storage Cleaner)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))

                Spacer()

                // 1-Click Clean All Safe Button
                Button {
                    cleanAllSafeCaches()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: isCleaningAll ? "hourglass" : "sparkles")
                            .font(.system(size: 10, weight: .bold))
                        Text(isCleaningAll ? "Đang dọn..." : "Dọn sạch 1-Click")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "10B981"))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isCleaningAll)
                .help("Tự động dọn toàn bộ các cache an toàn 100% (tự sinh lại khi build)")
            }

            VStack(spacing: 7) {
                // Xcode DerivedData (100% Safe)
                smartCacheRow(
                    title: "Xcode DerivedData",
                    pathNote: "Cache build tạm & index file",
                    size: derivedDataSize,
                    safety: .safe,
                    iconName: "hammer.fill",
                    iconColor: Color(hex: "3B82F6")
                ) {
                    cleanSingleItem(command: "rm -rf ~/Library/Developer/Xcode/DerivedData/*") {
                        await calculateSingleSize(type: .derivedData)
                    }
                }

                // Android Gradle Caches (100% Safe)
                smartCacheRow(
                    title: "Android Gradle Caches",
                    pathNote: "Build cache & downloaded jars (~/.gradle/caches)",
                    size: gradleCacheSize,
                    safety: .safe,
                    iconName: "play.circle.fill",
                    iconColor: Color(hex: "10B981")
                ) {
                    cleanSingleItem(command: "rm -rf ~/.gradle/caches/*") {
                        await calculateSingleSize(type: .gradle)
                    }
                }

                // CocoaPods & SPM Cache (100% Safe)
                smartCacheRow(
                    title: "Swift PM & CocoaPods",
                    pathNote: "Zip cache các thư viện bên thứ ba",
                    size: packageCacheSize,
                    safety: .safe,
                    iconName: "shippingbox.fill",
                    iconColor: Color(hex: "8B5CF6")
                ) {
                    cleanSingleItem(command: "rm -rf ~/Library/Caches/org.swift.swiftpm/* && rm -rf ~/Library/Caches/CocoaPods/*") {
                        await calculateSingleSize(type: .packages)
                    }
                }

                // iOS DeviceSupport (100% Safe)
                smartCacheRow(
                    title: "iOS DeviceSupport Symbols",
                    pathNote: "Symbol máy thật cũ từng cắm cáp",
                    size: deviceSupportSize,
                    safety: .safe,
                    iconName: "iphone.badge.play",
                    iconColor: Color(hex: "06B6D4")
                ) {
                    cleanSingleItem(command: "rm -rf ~/Library/Developer/Xcode/\"iOS DeviceSupport\"/*") {
                        await calculateSingleSize(type: .deviceSupport)
                    }
                }

                // Simulator Logs & Caches (100% Safe)
                smartCacheRow(
                    title: "Simulator Caches & Logs",
                    pathNote: "Log chạy máy ảo & cache simulator",
                    size: simLogsSize,
                    safety: .safe,
                    iconName: "doc.text.magnifyingglass",
                    iconColor: Color(hex: "64748B")
                ) {
                    cleanSingleItem(command: "rm -rf ~/Library/Logs/CoreSimulator/* && rm -rf ~/Library/Developer/CoreSimulator/Caches/*") {
                        await calculateSingleSize(type: .simLogs)
                    }
                }

                // Xcode Archives (Selective)
                smartCacheRow(
                    title: "Xcode Archives (Bản build cũ)",
                    pathNote: "Lưu trữ bản release đã đẩy App Store",
                    size: archivesSize,
                    safety: .selective,
                    iconName: "archivebox.fill",
                    iconColor: Color(hex: "F59E0B"),
                    extraActionTitle: "Xem Finder"
                ) {
                    let home = FileManager.default.homeDirectoryForCurrentUser.path
                    let url = URL(fileURLWithPath: "\(home)/Library/Developer/Xcode/Archives")
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    // MARK: - 3. Quick Media Access
    private var mediaAccessHub: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "8B5CF6"))

                Text("Thư Mục Xuất Media")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }

            HStack(spacing: 8) {
                mediaFolderButton(
                    title: "Screenshots",
                    icon: "photo.on.rectangle.angled",
                    folderName: "MobileDevBar_Screenshots"
                )

                mediaFolderButton(
                    title: "Screen Recordings",
                    icon: "video.badge.waveform",
                    folderName: "MobileDevBar_Recordings"
                )
            }
        }
    }

    // MARK: - 4. Emergency & Reset
    private var emergencyResetHub: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "bolt.badge.clock.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "F43F5E"))

                Text("Lệnh Khẩn Cấp & Reset")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }

            HStack(spacing: 7) {
                // Restart ADB
                Button {
                    restartADB()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold))
                        Text(isRestartingADB ? "Đang reset..." : "Restart ADB")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRestartingADB)
                .help("Khởi động lại adb daemon khi bị lỗi kết nối Android")

                Spacer()

                // Kill Simulators
                Button(role: .destructive) {
                    Task { await viewModel.killAllSimulators() }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 10))
                        Text("Tắt Simulators")
                            .font(.system(size: 10.5, design: .rounded))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                // Kill Emulators
                Button(role: .destructive) {
                    Task { await viewModel.killAllEmulators() }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 10))
                        Text("Tắt Emulators")
                            .font(.system(size: 10.5, design: .rounded))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Subviews & Helpers
    private enum CacheSafety {
        case safe
        case selective

        var badgeLabel: String {
            switch self {
            case .safe: return "100% Safe"
            case .selective: return "Selective"
            }
        }

        var badgeColor: Color {
            switch self {
            case .safe: return Color(hex: "10B981")
            case .selective: return Color(hex: "F59E0B")
            }
        }
    }

    private func smartCacheRow(
        title: String,
        pathNote: String,
        size: String,
        safety: CacheSafety,
        iconName: String,
        iconColor: Color,
        extraActionTitle: String = "Dọn dẹp",
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 12))
                .foregroundColor(iconColor)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))

                    // Safety Pill
                    Text(safety.badgeLabel)
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(safety.badgeColor.opacity(0.15))
                        .foregroundColor(safety.badgeColor)
                        .clipShape(Capsule())
                }

                Text(pathNote)
                    .font(.system(size: 9.5, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(size)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)

            Button(role: safety == .safe ? .destructive : .none) {
                action()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: safety == .safe ? "trash" : "arrow.up.forward.app")
                        .font(.system(size: 9))
                    Text(extraActionTitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.cardBackground())
    }

    private func mediaFolderButton(title: String, icon: String, folderName: String) -> some View {
        Button {
            openMediaFolder(name: folderName)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8B5CF6"))

                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))

                Spacer()

                Image(systemName: "arrow.up.forward.square")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(9)
            .frame(maxWidth: .infinity)
            .background(AppTheme.cardBackground())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Size Calculation Logic
    private enum SizeType {
        case derivedData
        case gradle
        case packages
        case deviceSupport
        case simLogs
        case archives
    }

    private func calculateAllSizes() async {
        await calculateSingleSize(type: .derivedData)
        await calculateSingleSize(type: .gradle)
        await calculateSingleSize(type: .packages)
        await calculateSingleSize(type: .deviceSupport)
        await calculateSingleSize(type: .simLogs)
        await calculateSingleSize(type: .archives)
    }

    private func calculateSingleSize(type: SizeType) async {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        switch type {
        case .derivedData:
            self.derivedDataSize = await getFolderSize("\(home)/Library/Developer/Xcode/DerivedData")
        case .gradle:
            self.gradleCacheSize = await getFolderSize("\(home)/.gradle/caches")
        case .packages:
            let spm = await getFolderSizeBytes("\(home)/Library/Caches/org.swift.swiftpm")
            let pods = await getFolderSizeBytes("\(home)/Library/Caches/CocoaPods")
            self.packageCacheSize = formatBytes(spm + pods)
        case .deviceSupport:
            self.deviceSupportSize = await getFolderSize("\(home)/Library/Developer/Xcode/iOS DeviceSupport")
        case .simLogs:
            let logs = await getFolderSizeBytes("\(home)/Library/Logs/CoreSimulator")
            let cache = await getFolderSizeBytes("\(home)/Library/Developer/CoreSimulator/Caches")
            self.simLogsSize = formatBytes(logs + cache)
        case .archives:
            self.archivesSize = await getFolderSize("\(home)/Library/Developer/Xcode/Archives")
        }
    }

    private func getFolderSize(_ path: String) async -> String {
        guard FileManager.default.fileExists(atPath: path) else { return "0 B" }
        do {
            let res = try await ShellService.shared.run("du -sh \"\(path)\" 2>/dev/null | awk '{print $1}'")
            let trimmed = res.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "0 B" : trimmed
        } catch {
            return "0 B"
        }
    }

    private func getFolderSizeBytes(_ path: String) async -> Int64 {
        guard FileManager.default.fileExists(atPath: path) else { return 0 }
        do {
            let res = try await ShellService.shared.run("du -sk \"\(path)\" 2>/dev/null | awk '{print $1}'")
            let kb = Int64(res.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            return kb * 1024
        } catch {
            return 0
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Cleaning Actions
    private func cleanSingleItem(command: String, then: @escaping () async -> Void) {
        Task {
            _ = try? await ShellService.shared.run(command)
            await then()
        }
    }

    private func cleanAllSafeCaches() {
        isCleaningAll = true
        Task {
            let cmd = """
            rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null
            rm -rf ~/.gradle/caches/* 2>/dev/null
            rm -rf ~/Library/Caches/org.swift.swiftpm/* 2>/dev/null
            rm -rf ~/Library/Caches/CocoaPods/* 2>/dev/null
            rm -rf ~/Library/Developer/Xcode/"iOS DeviceSupport"/* 2>/dev/null
            rm -rf ~/Library/Logs/CoreSimulator/* 2>/dev/null
            rm -rf ~/Library/Developer/CoreSimulator/Caches/* 2>/dev/null
            """
            _ = try? await ShellService.shared.run(cmd)
            await calculateAllSizes()
            isCleaningAll = false
        }
    }

    private func fetchLocalIP() async {
        do {
            let ip = try await ShellService.shared.run("ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo '127.0.0.1'")
            self.localIP = ip.isEmpty ? "127.0.0.1" : ip
        } catch {
            self.localIP = "127.0.0.1"
        }
    }

    private func openMediaFolder(name: String) {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        if let folder = desktop?.appendingPathComponent(name, isDirectory: true) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            NSWorkspace.shared.open(folder)
        }
    }

    private func restartADB() {
        isRestartingADB = true
        Task {
            _ = try? await ShellService.shared.run("adb kill-server && adb start-server")
            await viewModel.refreshAll()
            isRestartingADB = false
        }
    }
}
