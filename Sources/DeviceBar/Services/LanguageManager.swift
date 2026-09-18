import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case vietnamese = "vi"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }

    public var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .vietnamese: return "🇻🇳"
        }
    }
}

@MainActor
public final class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()

    private let userDefaultsKey = "devicebar_app_language"

    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)
        }
    }

    public init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Default to English or system preferred
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.starts(with: "vi") {
                self.currentLanguage = .vietnamese
            } else {
                self.currentLanguage = .english
            }
        }
    }

    public func setLanguage(_ language: AppLanguage) {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.currentLanguage = language
        }
    }

    public func tr(_ key: String) -> String {
        if currentLanguage == .vietnamese {
            return vietnameseTranslations[key] ?? key
        } else {
            return englishTranslations[key] ?? key
        }
    }

    // MARK: - Dictionary Translations
    private let englishTranslations: [String: String] = [
        // Tabs
        "tab_simulators": "Simulators & AVD",
        "tab_physical_devices": "Devices & Mirroring",
        "tab_tools": "Quick Tools",
        "tab_settings": "Settings",

        // Header & Status
        "app_title": "DeviceBar",
        "booted": "Booted",
        "refresh_tooltip": "Refresh device lists (Cmd+R)",
        "settings_tooltip": "DeviceBar Settings & Preferences",
        "ready_status": "Ready • Device controller active",

        // Search & Filter
        "search_placeholder": "Search simulators by name, iOS / API version...",
        "filter_booted_only": "Running",
        "filter_booted_tooltip": "Show only booted simulators & running emulators",

        // Simulator & Android Actions
        "boot": "Boot",
        "shutdown": "Shutdown",
        "erase": "Erase Content & Settings",
        "cold_boot": "Cold Boot",
        "wipe_data": "Wipe User Data",
        "delete": "Delete",
        "copy_id": "Copy ID",
        "confirm_delete_sim": "Are you sure you want to delete this simulator?",
        "confirm_erase_sim": "Erase all data and reset this simulator?",
        "confirm_wipe_avd": "Wipe all user data for this Android AVD?",

        // Mirroring & Devices
        "no_physical_devices": "No connected devices found",
        "connect_device_hint": "Connect an iPhone/iPad via Lightning/Type-C or an Android device with USB Debugging enabled.",
        "start_mirroring": "Start Mirroring",
        "wireless_mirroring": "Wireless Connect",
        "disconnect": "Disconnect",
        "battery": "Battery",

        // Quick Tools Hub
        "lan_ip_title": "Local IP Address (LAN IP)",
        "lan_ip_subtitle": "Use this IP to call backend server from mobile devices",
        "copy": "Copy",
        "copied": "Copied",
        "storage_cleaner_title": "Developer Storage Cleaner",
        "storage_cleaner_subtitle": "Safely free up Xcode DerivedData, Gradle Cache & Device Logs",
        "clean_all": "Clean All Safe Caches",
        "cleaning": "Cleaning...",
        "derived_data": "Xcode DerivedData",
        "gradle_cache": "Android Gradle Cache",
        "device_support": "iOS DeviceSupport",
        "package_cache": "SwiftPM & SPM Cache",
        "sim_logs": "Simulator Logs & Caches",
        "archives": "Xcode Archives",
        "media_access_title": "Quick Screenshots & Recordings",
        "media_access_subtitle": "Instant access to media captured from devices",
        "open_screenshots": "Open Screenshots Folder",
        "open_recordings": "Open Screen Recordings",
        "restart_adb": "Restart ADB Server",
        "restart_adb_desc": "Kill & restart ADB daemon when Android devices are unresponsive",
        "restarting": "Restarting...",
        "restarted": "Restarted",

        // Debugger / Network Inspector
        "network_inspector_title": "Network & API Inspector",
        "network_inspector_desc": "Monitor HTTP/HTTPS traffic, catch failed APIs, and export cURL",
        "open_network_inspector": "Open Network Inspector",
        "crash_detective_title": "Crash Detective",
        "crash_detective_desc": "Automatically detect crashes and inspect native stack traces",
        "open_crash_detective": "Open Crash Detective",
        "export_all_markdown": "Export All (.md)",
        "export_all_clipboard": "Copy All as Markdown",
        "clear_logs": "Clear Logs",
        "filter_all": "All",
        "filter_errors": "Errors Only (4xx/5xx)",
        "filter_search": "Filter by URL, method or status...",

        // Settings View
        "settings_header": "Settings & Preferences",
        "settings_language": "Language",
        "settings_language_desc": "Choose interface display language",
        "settings_general": "General",
        "settings_launch_at_login": "Launch at macOS Login",
        "settings_launch_at_login_desc": "Automatically start DeviceBar when logging in",
        "settings_auto_refresh": "Device Auto-Refresh Interval",
        "settings_auto_refresh_desc": "Frequency of background hardware discovery checks",
        "refresh_fast": "Fast (1.5s)",
        "refresh_normal": "Standard (3s)",
        "refresh_slow": "Low Battery (6s)",
        "refresh_manual": "Manual Only",
        "install_app": "Install to /Applications",
        "install_app_desc": "Copy DeviceBar into system Applications folder",
        "open_app_folder": "Open /Applications Folder",

        // Environment & SDKs
        "settings_environment": "Developer Environment",
        "xcode_tools": "Xcode Command Line Tools",
        "android_sdk_adb": "Android SDK & ADB",
        "scrcpy_tool": "Scrcpy (Screen Mirroring)",
        "status_installed": "Installed",
        "status_not_found": "Not Found",
        "detected_at": "Found at",
        "install_guide_scrcpy": "Run 'brew install scrcpy' to enable 60fps Android screen mirroring.",

        // Network Inspector Settings
        "settings_network_inspector": "Network Inspector Settings",
        "buffer_size": "Log Buffer Capacity",
        "buffer_size_desc": "Maximum number of HTTP requests kept in memory",
        "auto_capture": "Auto-Capture Background Logs",
        "auto_capture_desc": "Continuously scan for new mobile network traffic",

        // About
        "settings_about": "About DeviceBar",
        "version": "Version",
        "github_repo": "GitHub Repository",
        "open_github": "View on GitHub",
        "license": "License: MIT Open Source",
        "quit_app": "Quit DeviceBar"
    ]

    private let vietnameseTranslations: [String: String] = [
        // Tabs
        "tab_simulators": "Máy ảo & AVD",
        "tab_physical_devices": "Thiết bị & Phản chiếu",
        "tab_tools": "Công cụ nhanh",
        "tab_settings": "Cài đặt",

        // Header & Status
        "app_title": "DeviceBar",
        "booted": "Đang chạy",
        "refresh_tooltip": "Làm mới danh sách thiết bị (Cmd+R)",
        "settings_tooltip": "Cài đặt & Tuỳ chọn DeviceBar",
        "ready_status": "Ready • Sẵn sàng điều khiển thiết bị",

        // Search & Filter
        "search_placeholder": "Tìm máy ảo theo tên, iOS / API version...",
        "filter_booted_only": "Đang chạy",
        "filter_booted_tooltip": "Chỉ lọc các máy ảo đang chạy",

        // Simulator & Android Actions
        "boot": "Khởi động",
        "shutdown": "Tắt nguồn",
        "erase": "Xoá dữ liệu & Reset máy ảo",
        "cold_boot": "Cold Boot (Khởi động sạch)",
        "wipe_data": "Wipe User Data (Xoá data AVD)",
        "delete": "Xoá bỏ",
        "copy_id": "Sao chép ID",
        "confirm_delete_sim": "Bạn có chắc chắn muốn xoá máy ảo này không?",
        "confirm_erase_sim": "Xoá toàn bộ dữ liệu và reset máy ảo này?",
        "confirm_wipe_avd": "Xoá sạch toàn bộ dữ liệu người dùng trên AVD này?",

        // Mirroring & Devices
        "no_physical_devices": "Chưa tìm thấy thiết bị nào kết nối",
        "connect_device_hint": "Kết nối iPhone/iPad qua cáp hoặc thiết bị Android đã bật Gỡ lỗi USB (USB Debugging).",
        "start_mirroring": "Phản chiếu màn hình",
        "wireless_mirroring": "Kết nối không dây",
        "disconnect": "Ngắt kết nối",
        "battery": "Pin",

        // Quick Tools Hub
        "lan_ip_title": "Địa Chỉ IP Nội Bộ (LAN IP)",
        "lan_ip_subtitle": "Dùng địa chỉ này để gọi backend server từ điện thoại thật",
        "copy": "Sao chép",
        "copied": "Đã chép",
        "storage_cleaner_title": "Dọn Dẹp Bộ Nhớ Developer",
        "storage_cleaner_subtitle": "Giải phóng an toàn Xcode DerivedData, Gradle Cache & Logs",
        "clean_all": "Dọn Dẹp Toàn Bộ Cache An Toàn",
        "cleaning": "Đang dọn dẹp...",
        "derived_data": "Xcode DerivedData",
        "gradle_cache": "Android Gradle Cache",
        "device_support": "iOS DeviceSupport",
        "package_cache": "Bộ nhớ đệm SwiftPM / SPM",
        "sim_logs": "Simulator Logs & Cache",
        "archives": "Xcode Archives",
        "media_access_title": "Ảnh & Video Chụp Màn Hình",
        "media_access_subtitle": "Truy cập nhanh các tập tin chụp từ thiết bị",
        "open_screenshots": "Mở thư mục Ảnh Chụp",
        "open_recordings": "Mở thư mục Video Quay",
        "restart_adb": "Khởi Động Lại ADB Server",
        "restart_adb_desc": "Khởi động lại ADB daemon khi thiết bị Android mất kết nối",
        "restarting": "Đang khởi động lại...",
        "restarted": "Đã khởi động lại",

        // Debugger / Network Inspector
        "network_inspector_title": "Bộ Giám Sát Network & API",
        "network_inspector_desc": "Theo dõi HTTP/HTTPS, bắt lỗi API và xuất cURL tiện lợi",
        "open_network_inspector": "Mở Trình Soi Network & API",
        "crash_detective_title": "Thám Tử Bắt Crash (Crash Detective)",
        "crash_detective_desc": "Tự động phát hiện crash ứng dụng và xem chi tiết stack trace",
        "open_crash_detective": "Mở Trình Soi Crash",
        "export_all_markdown": "Xuất Toàn Bộ (.md)",
        "export_all_clipboard": "Sao Chép Toàn Bộ (.md)",
        "clear_logs": "Xoá Nhật Ký",
        "filter_all": "Tất cả",
        "filter_errors": "Chỉ lỗi (4xx/5xx)",
        "filter_search": "Lọc theo URL, method hoặc mã HTTP...",

        // Settings View
        "settings_header": "Cài Đặt & Tuỳ Chọn",
        "settings_language": "Ngôn ngữ hiển thị",
        "settings_language_desc": "Chọn ngôn ngữ giao diện của DeviceBar",
        "settings_general": "Hệ thống & Chung",
        "settings_launch_at_login": "Khởi động cùng máy Mac",
        "settings_launch_at_login_desc": "Tự động mở DeviceBar khi đăng nhập vào macOS",
        "settings_auto_refresh": "Chu kỳ tự động làm mới thiết bị",
        "settings_auto_refresh_desc": "Tần suất quét phần cứng và máy ảo ngầm",
        "refresh_fast": "Nhanh (1.5s)",
        "refresh_normal": "Tiêu chuẩn (3s)",
        "refresh_slow": "Tiết kiệm pin (6s)",
        "refresh_manual": "Chỉ làm mới thủ công",
        "install_app": "Cài đặt vào /Applications",
        "install_app_desc": "Sao chép DeviceBar vào thư mục Ứng dụng hệ thống",
        "open_app_folder": "Mở thư mục /Applications",

        // Environment & SDKs
        "settings_environment": "Môi Trường & Công Cụ Lập Trình",
        "xcode_tools": "Xcode Command Line Tools",
        "android_sdk_adb": "Android SDK & ADB",
        "scrcpy_tool": "Scrcpy (Phản chiếu màn hình)",
        "status_installed": "Đã cài đặt",
        "status_not_found": "Chưa tìm thấy",
        "detected_at": "Đường dẫn",
        "install_guide_scrcpy": "Chạy 'brew install scrcpy' để phản chiếu Android mượt mà 60fps.",

        // Network Inspector Settings
        "settings_network_inspector": "Cấu Hình Network Inspector",
        "buffer_size": "Dung lượng bộ đệm Logs",
        "buffer_size_desc": "Số lượng yêu cầu API tối đa được lưu trong bộ nhớ",
        "auto_capture": "Tự động bắt log ngầm",
        "auto_capture_desc": "Liên tục lắng nghe lưu lượng mạng di động mới",

        // About
        "settings_about": "Thông Tin DeviceBar",
        "version": "Phiên bản",
        "github_repo": "Kho mã nguồn GitHub",
        "open_github": "Mở trên GitHub",
        "license": "Giấy phép: MIT Mã nguồn mở",
        "quit_app": "Thoát DeviceBar"
    ]
}

// Global helper function
@MainActor
public func loc(_ key: String) -> String {
    LanguageManager.shared.tr(key)
}
