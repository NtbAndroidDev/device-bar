import Foundation
import SwiftUI
import AppKit
import ServiceManagement

@MainActor
public final class AppViewModel: ObservableObject {
    // MARK: - Published State
    @Published public var simulators: [SimulatorDevice] = []
    @Published public var androidAVDs: [AndroidAVD] = []
    @Published public var connectedDevices: [ConnectedDevice] = []

    @Published public var isLoading: Bool = false
    @Published public var statusMessage: String?
    @Published public var isErrorStatus: Bool = false
    @Published public var isLaunchAtLogin: Bool = false

    @Published public var searchText: String = ""
    @Published public var filterBootedOnly: Bool = false
    @Published public var selectedTab: Tab = .simulators

    // Deep Link & Location helpers
    @Published public var deepLinkURL: String = ""
    @Published public var selectedLocationPreset: LocationPreset = LocationPreset.defaults[0]
    @Published public var customLatitude: String = "21.0285"
    @Published public var customLongitude: String = "105.8542"

    public enum Tab: String, CaseIterable {
        case simulators = "Simulators & AVD"
        case physicalDevices = "Devices & Mirroring"
        case tools = "Quick Tools"

        public var icon: String {
            switch self {
            case .simulators: return "macbook.and.iphone"
            case .physicalDevices: return "display.trianglebadge.exclamationmark"
            case .tools: return "wrench.and.screwdriver"
            }
        }
    }

    private let simService = SimulatorService.shared
    private let androidService = AndroidService.shared
    private var refreshTimer: Timer?

    public init() {
        self.isLaunchAtLogin = SMAppService.mainApp.status == .enabled

        Task {
            await refreshAll()
        }

        // Auto-refresh ngầm mỗi 2.5s để cập nhật chính xác theo thời gian thực
        self.refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isLoading else { return }
                await self.refreshAllQuietly()
            }
        }
    }

    public func toggleLaunchAtLogin() {
        do {
            if isLaunchAtLogin {
                try SMAppService.mainApp.unregister()
                self.isLaunchAtLogin = false
                showStatus("Đã tắt khởi động cùng macOS")
            } else {
                try SMAppService.mainApp.register()
                self.isLaunchAtLogin = true
                showStatus("Đã bật khởi động cùng macOS!")
            }
        } catch {
            showError("Lỗi cài đặt khởi động: \(error.localizedDescription)")
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    // MARK: - Filtered Lists (Prioritizing Active / In-Progress Devices to the Top)
    public var filteredSimulators: [SimulatorDevice] {
        simulators
            .filter { device in
                let matchesSearch = searchText.isEmpty ||
                    device.name.localizedCaseInsensitiveContains(searchText) ||
                    device.osVersion.localizedCaseInsensitiveContains(searchText)
                let matchesBooted = !filterBootedOnly || device.state.isBooted
                return matchesSearch && matchesBooted
            }
            .sorted { a, b in
                // 1. Thằng nào đang progress / active thì luôn đưa lên đầu
                if a.isProgressOrActive != b.isProgressOrActive {
                    return a.isProgressOrActive && !b.isProgressOrActive
                }
                // 2. Cùng trạng thái thì sắp xếp theo tên A-Z
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
    }

    public var filteredAVDs: [AndroidAVD] {
        androidAVDs
            .filter { avd in
                let matchesSearch = searchText.isEmpty || avd.name.localizedCaseInsensitiveContains(searchText)
                let matchesBooted = !filterBootedOnly || avd.isRunning
                return matchesSearch && matchesBooted
            }
            .sorted { a, b in
                // 1. Thằng nào đang running thì luôn đưa lên đầu
                if a.isRunning != b.isRunning {
                    return a.isRunning && !b.isRunning
                }
                // 2. Cùng trạng thái thì sắp xếp theo tên A-Z
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
    }

    /// Danh sách tất cả máy ảo (cả iOS lẫn Android) đang trong tiến trình chạy thực tế
    public var activeSimulatorsList: [SimulatorDevice] {
        filteredSimulators.filter { $0.isProgressOrActive }
    }

    public var inactiveSimulatorsList: [SimulatorDevice] {
        filteredSimulators.filter { !$0.isProgressOrActive }
    }

    public var activeAVDsList: [AndroidAVD] {
        filteredAVDs.filter { $0.isRunning }
    }

    public var inactiveAVDsList: [AndroidAVD] {
        filteredAVDs.filter { !$0.isRunning }
    }

    /// Tổng số máy ảo đang chạy thực tế (cả iOS Simulator Booted + Android AVD Running)
    public var bootedSimulatorsCount: Int {
        simulators.filter { $0.state.isBooted }.count + androidAVDs.filter { $0.isRunning }.count
    }

    // MARK: - Refresh Data
    public func refreshAll() async {
        isLoading = true
        defer { isLoading = false }
        await refreshAllQuietly()
    }

    /// Cập nhật dữ liệu từ hệ điều hành mà không giật spinner
    public func refreshAllQuietly() async {
        async let fetchedSims = (try? await simService.fetchSimulators()) ?? []
        async let fetchedAVDs = await androidService.fetchAVDs()
        async let fetchedDevices = await androidService.fetchConnectedDevices()

        let sims = await fetchedSims
        let avds = await fetchedAVDs
        let devices = await fetchedDevices

        // Chỉ gán khi có sự thay đổi để tránh re-render thừa
        if self.simulators != sims {
            self.simulators = sims
        }
        if self.androidAVDs != avds {
            self.androidAVDs = avds
        }
        if self.connectedDevices != devices {
            self.connectedDevices = devices
        }
    }


    // MARK: - iOS Simulator Actions
    public func bootSimulator(_ device: SimulatorDevice) async {
        showStatus("Đang khởi động \(device.name)...")
        do {
            try await simService.boot(udid: device.udid)
            await refreshAll()
            showStatus("Đã khởi động \(device.name)!")
        } catch {
            showError("Lỗi khởi động: \(error.localizedDescription)")
        }
    }

    public func shutdownSimulator(_ device: SimulatorDevice) async {
        showStatus("Đang tắt \(device.name)...")
        do {
            try await simService.shutdown(udid: device.udid)
            await refreshAll()
            showStatus("Đã tắt \(device.name)")
        } catch {
            showError("Lỗi tắt máy: \(error.localizedDescription)")
        }
    }

    public func eraseSimulator(_ device: SimulatorDevice) async {
        showStatus("Đang xóa dữ liệu (wipe) \(device.name)...")
        do {
            try await simService.erase(udid: device.udid)
            await refreshAll()
            showStatus("Đã xoá dữ liệu \(device.name) hoàn tất!")
        } catch {
            showError("Lỗi xoá dữ liệu: \(error.localizedDescription)")
        }
    }

    public func killAllSimulators() async {
        showStatus("Đang tắt toàn bộ Simulators...")
        do {
            try await simService.killAllSimulators()
            await refreshAll()
            showStatus("Đã tắt toàn bộ Simulators!")
        } catch {
            showError("Lỗi: \(error.localizedDescription)")
        }
    }

    public func toggleAppearance(device: SimulatorDevice, dark: Bool) async {
        do {
            try await simService.toggleAppearance(udid: device.udid, dark: dark)
            showStatus("Đã chuyển giao diện sang \(dark ? "Dark Mode" : "Light Mode")")
        } catch {
            showError("Lỗi đổi theme: \(error.localizedDescription)")
        }
    }

    public func triggerBiometric(device: SimulatorDevice, match: Bool) async {
        do {
            try await simService.triggerBiometric(udid: device.udid, match: match)
            showStatus("FaceID: \(match ? "Thành công (Match)" : "Thất bại (Fail)")")
        } catch {
            showError("Lỗi kích hoạt FaceID: \(error.localizedDescription)")
        }
    }

    public func setMockLocation(device: SimulatorDevice, preset: LocationPreset) async {
        do {
            try await simService.setLocation(udid: device.udid, latitude: preset.latitude, longitude: preset.longitude)
            showStatus("Đã đặt vị trí giả lập: \(preset.name)")
        } catch {
            showError("Lỗi set tọa độ: \(error.localizedDescription)")
        }
    }

    public func openDeepLink(device: SimulatorDevice, url: String) async {
        guard !url.isEmpty else { return }
        do {
            try await simService.openURL(udid: device.udid, urlString: url)
            showStatus("Đã mở link: \(url)")
        } catch {
            showError("Lỗi mở link: \(error.localizedDescription)")
        }
    }

    public func changeSimulatorLocale(device: SimulatorDevice, preset: LocalePreset) async {
        do {
            try await simService.changeLocale(udid: device.udid, preset: preset)
            showStatus("Đã đổi ngôn ngữ \(device.name) sang \(preset.name)")
        } catch {
            showError("Lỗi đổi ngôn ngữ: \(error.localizedDescription)")
        }
    }

    public func captureSimScreenshot(
        device: SimulatorDevice,
        mask: ScreenshotMask = .alpha,
        saveToDesktop: Bool = false
    ) async {
        showStatus("Đang chụp màn hình (\(mask.title))...")
        do {
            let url = try await simService.captureScreenshot(udid: device.udid, mask: mask, saveToDesktop: saveToDesktop)
            showStatus("Đã chụp \(mask.title) & copy Clipboard! (\(url.lastPathComponent))")
        } catch {
            showError("Lỗi chụp ảnh: \(error.localizedDescription)")
        }
    }

    public func recordSimVideo(device: SimulatorDevice, durationSeconds: Int = 10) async {
        showStatus("Đang quay video \(durationSeconds)s trên \(device.name)...")
        do {
            let url = try await simService.recordVideo(udid: device.udid, durationSeconds: durationSeconds)
            showStatus("Đã lưu video vào Desktop (\(url.lastPathComponent))")
        } catch {
            showError("Lỗi quay video: \(error.localizedDescription)")
        }
    }

    // MARK: - Android AVD Actions
    public func startAVD(_ avd: AndroidAVD, coldBoot: Bool = false, wipeData: Bool = false) async {
        showStatus("Đang mở AVD \(avd.name)...")
        do {
            try await androidService.startAVD(name: avd.name, coldBoot: coldBoot, wipeData: wipeData)
            showStatus("Đã gửi lệnh khởi động AVD \(avd.name)")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await refreshAll()
        } catch {
            showError("Lỗi khởi động AVD: \(error.localizedDescription)")
        }
    }

    public func killAVD(_ avd: AndroidAVD) async {
        guard let serial = avd.runningSerial else { return }
        showStatus("Đang tắt AVD \(avd.name)...")
        do {
            try await androidService.killAVD(serial: serial)
            await refreshAll()
            showStatus("Đã tắt AVD \(avd.name)")
        } catch {
            showError("Lỗi tắt AVD: \(error.localizedDescription)")
        }
    }

    public func killAllEmulators() async {
        showStatus("Đang tắt toàn bộ Android Emulators...")
        do {
            try await androidService.killAllEmulators()
            await refreshAll()
            showStatus("Đã tắt toàn bộ Android Emulators!")
        } catch {
            showError("Lỗi: \(error.localizedDescription)")
        }
    }

    // MARK: - Physical Devices & Android Actions
    public func addSamplePhoto(device: SimulatorDevice) async {
        showStatus("Đang nạp ảnh mẫu vào Photos của \(device.name)...")
        do {
            try await simService.addSamplePhoto(udid: device.udid)
            showStatus("Đã thêm ảnh mẫu vào Photos.app thành công!")
        } catch {
            showError("Lỗi thêm ảnh: \(error.localizedDescription)")
        }
    }

    public func syncClipboard(device: SimulatorDevice) async {
        do {
            try await simService.syncClipboardMacToSimulator(udid: device.udid)
            showStatus("Đã đồng bộ Clipboard từ Mac sang Simulator!")
        } catch {
            showError("Lỗi đồng bộ clipboard: \(error.localizedDescription)")
        }
    }

    // MARK: - Android Quick Tweaks
    public func toggleAndroidAppearance(avd: AndroidAVD, dark: Bool) async {
        guard let serial = avd.runningSerial else { return }
        do {
            try await androidService.toggleAppearance(serial: serial, dark: dark)
            showStatus("Đã chuyển AVD sang \(dark ? "Dark Mode" : "Light Mode")")
        } catch {
            showError("Lỗi đổi theme Android: \(error.localizedDescription)")
        }
    }

    public func setAndroidMockLocation(avd: AndroidAVD, preset: LocationPreset) async {
        guard let serial = avd.runningSerial else { return }
        do {
            try await androidService.setLocation(serial: serial, latitude: preset.latitude, longitude: preset.longitude)
            showStatus("Đã đặt vị trí Android: \(preset.name)")
        } catch {
            showError("Lỗi đặt vị trí GPS: \(error.localizedDescription)")
        }
    }

    public func openAndroidDeepLink(avd: AndroidAVD, url: String) async {
        guard let serial = avd.runningSerial, !url.isEmpty else { return }
        do {
            try await androidService.openURL(serial: serial, urlString: url)
            showStatus("Đã mở link trên Android: \(url)")
        } catch {
            showError("Lỗi mở URL scheme: \(error.localizedDescription)")
        }
    }

    public func toggleAndroidTouches(avd: AndroidAVD, enabled: Bool) async {
        guard let serial = avd.runningSerial else { return }
        do {
            try await androidService.toggleShowTouches(serial: serial, enabled: enabled)
            showStatus(enabled ? "Đã bật hiển thị chạm màn hình (Show Touches)" : "Đã tắt Show Touches")
        } catch {
            showError("Lỗi bật/tắt Show Touches: \(error.localizedDescription)")
        }
    }

    public func openAndroidDevSettings(avd: AndroidAVD) async {
        guard let serial = avd.runningSerial else { return }
        do {
            try await androidService.openDevSettings(serial: serial)
            showStatus("Đã mở Developer Settings trên AVD")
        } catch {
            showError("Lỗi mở cài đặt: \(error.localizedDescription)")
        }
    }

    public func changeAndroidLocale(serial: String, preset: LocalePreset) async {
        do {
            try await androidService.changeLocale(serial: serial, preset: preset)
            showStatus("Đã đổi ngôn ngữ sang \(preset.name)")
        } catch {
            showError("Lỗi đổi ngôn ngữ: \(error.localizedDescription)")
        }
    }


    public func launchMirroring(device: ConnectedDevice) async {
        showStatus("Đang mở màn hình chiếu (scrcpy) cho \(device.name)...")
        do {
            try await androidService.launchMirroring(serial: device.serial)
            showStatus("Đang chiếu màn hình: \(device.name)")
        } catch {
            showError(error.localizedDescription)
        }
    }

    public func captureDeviceScreenshot(device: ConnectedDevice, saveToDesktop: Bool = false) async {
        showStatus("Đang chụp màn hình thiết bị...")
        do {
            if device.platform == .android {
                let fileURL = try await androidService.captureScreenshot(serial: device.serial, saveToDesktop: saveToDesktop)
                showStatus("Đã chụp & copy vào Clipboard! (\(fileURL.lastPathComponent))")
            } else {
                let fileURL = try await simService.captureScreenshot(udid: device.serial, mask: .alpha, saveToDesktop: saveToDesktop)
                showStatus("Đã chụp & copy vào Clipboard! (\(fileURL.lastPathComponent))")
            }
        } catch {
            showError("Lỗi chụp ảnh: \(error.localizedDescription)")
        }
    }

    public func recordDeviceVideo(device: ConnectedDevice, durationSeconds: Int = 10) async {
        showStatus("Đang quay màn hình thiết bị \(durationSeconds)s...")
        do {
            if device.platform == .android {
                let fileURL = try await androidService.startScreenRecord(serial: device.serial, durationSeconds: durationSeconds)
                showStatus("Đã lưu video vào Desktop! (\(fileURL.lastPathComponent))")
            } else {
                let fileURL = try await simService.recordVideo(udid: device.serial, durationSeconds: durationSeconds)
                showStatus("Đã lưu video vào Desktop! (\(fileURL.lastPathComponent))")
            }
        } catch {
            showError("Lỗi quay video: \(error.localizedDescription)")
        }
    }

    public func enableWifiAdb(device: ConnectedDevice) async {
        showStatus("Đang kích hoạt ADB qua Wi-Fi...")
        do {
            let result = try await androidService.enableWifiAdb(serial: device.serial)
            showStatus(result)
            await refreshAll()
        } catch {
            showError("Lỗi ADB Wi-Fi: \(error.localizedDescription)")
        }
    }

    // MARK: - Feedback Toasts
    public func showStatus(_ message: String) {
        self.isErrorStatus = false
        self.statusMessage = message
        dismissStatusAfterDelay()
    }

    public func showError(_ message: String) {
        self.isErrorStatus = true
        self.statusMessage = message
        dismissStatusAfterDelay()
    }

    private func dismissStatusAfterDelay() {
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if self.statusMessage != nil {
                self.statusMessage = nil
            }
        }
    }
}
