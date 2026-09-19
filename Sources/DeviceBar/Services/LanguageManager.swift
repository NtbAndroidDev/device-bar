import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case vietnamese = "vi"
    case japanese = "ja"
    case chinese = "zh"
    case korean = "ko"
    case spanish = "es"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        case .japanese: return "日本語"
        case .chinese: return "简体中文"
        case .korean: return "한국어"
        case .spanish: return "Español"
        }
    }

    public var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .vietnamese: return "🇻🇳"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        case .korean: return "🇰🇷"
        case .spanish: return "🇪🇸"
        }
    }

    public var code: String {
        switch self {
        case .english: return "EN"
        case .vietnamese: return "VI"
        case .japanese: return "JA"
        case .chinese: return "ZH"
        case .korean: return "KO"
        case .spanish: return "ES"
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
            // Default based on macOS preferred languages
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.starts(with: "vi") {
                self.currentLanguage = .vietnamese
            } else if preferred.starts(with: "ja") {
                self.currentLanguage = .japanese
            } else if preferred.starts(with: "zh") {
                self.currentLanguage = .chinese
            } else if preferred.starts(with: "ko") {
                self.currentLanguage = .korean
            } else if preferred.starts(with: "es") {
                self.currentLanguage = .spanish
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
        switch currentLanguage {
        case .vietnamese:
            return vietnameseTranslations[key] ?? englishTranslations[key] ?? key
        case .japanese:
            return japaneseTranslations[key] ?? englishTranslations[key] ?? key
        case .chinese:
            return chineseTranslations[key] ?? englishTranslations[key] ?? key
        case .korean:
            return koreanTranslations[key] ?? englishTranslations[key] ?? key
        case .spanish:
            return spanishTranslations[key] ?? englishTranslations[key] ?? key
        case .english:
            return englishTranslations[key] ?? key
        }
    }

    // MARK: - 1. English Translations
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
        "buy_me_a_coffee": "Buy Me a Coffee",
        "support": "Support",
        "quit_app": "Quit DeviceBar"
    ]

    // MARK: - 2. Vietnamese Translations
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
        "buy_me_a_coffee": "Mời cà phê",
        "support": "Ủng hộ",
        "quit_app": "Thoát DeviceBar"
    ]

    // MARK: - 3. Japanese Translations (日本語)
    private let japaneseTranslations: [String: String] = [
        "tab_simulators": "シミュレータ＆AVD",
        "tab_physical_devices": "実機＆ミラーリング",
        "tab_tools": "クイックツール",
        "tab_settings": "設定",

        "app_title": "DeviceBar",
        "booted": "起動中",
        "refresh_tooltip": "デバイスリストを更新 (Cmd+R)",
        "settings_tooltip": "DeviceBar 設定＆環境設定",
        "ready_status": "準備完了 • デバイスコントローラー待機中",

        "search_placeholder": "名前やiOS/APIバージョンで検索...",
        "filter_booted_only": "起動中のみ",
        "filter_booted_tooltip": "起動中のシミュレータとエミュレータのみ表示",

        "boot": "起動",
        "shutdown": "シャットダウン",
        "erase": "コンテンツと設定を消去",
        "cold_boot": "コールドブート",
        "wipe_data": "データ消去 (Wipe)",
        "delete": "削除",
        "copy_id": "IDをコピー",
        "confirm_delete_sim": "このシミュレータを削除してもよろしいですか？",
        "confirm_erase_sim": "すべてのデータを消去してリセットしますか？",
        "confirm_wipe_avd": "このAndroid AVDのユーザーデータを消去しますか？",

        "no_physical_devices": "接続された実機がありません",
        "connect_device_hint": "iPhone/iPadをUSB接続するか、USBデバッグを有効にしたAndroidを接続してください。",
        "start_mirroring": "画面ミラーリング開始",
        "wireless_mirroring": "Wi-Fi接続",
        "disconnect": "切断",
        "battery": "バッテリー",

        "lan_ip_title": "ローカルIPアドレス (LAN IP)",
        "lan_ip_subtitle": "実機からMacのバックエンドを呼び出す際に使用します",
        "copy": "コピー",
        "copied": "コピー完了",
        "storage_cleaner_title": "開発ストレージクリーナー",
        "storage_cleaner_subtitle": "Xcode DerivedData、Gradleキャッシュ、ログを安全に削除",
        "clean_all": "安全なキャッシュを一括削除",
        "cleaning": "クリーン中...",
        "derived_data": "Xcode DerivedData",
        "gradle_cache": "Android Gradle キャッシュ",
        "device_support": "iOS DeviceSupport",
        "package_cache": "SwiftPM＆CocoaPods キャッシュ",
        "sim_logs": "シミュレータログ＆キャッシュ",
        "archives": "Xcode アーカイブ",
        "media_access_title": "スクリーンショット＆録画",
        "media_access_subtitle": "キャプチャしたメディアフォルダへすばやくアクセス",
        "open_screenshots": "スクリーンショットフォルダを開く",
        "open_recordings": "画面録画フォルダを開く",
        "restart_adb": "ADBサーバー再起動",
        "restart_adb_desc": "Android実機が認識しない場合にADBデーモンを再起動します",
        "restarting": "再起動中...",
        "restarted": "再起動完了",

        "network_inspector_title": "ネットワーク＆APIインスペクター",
        "network_inspector_desc": "HTTP/HTTPSトラフィックを監視し、エラーを検知してcURLを出力",
        "open_network_inspector": "ネットワークインスペクターを開く",
        "crash_detective_title": "クラッシュディテクティブ",
        "crash_detective_desc": "アプリクラッシュを検知しスタックトレースを解析",
        "open_crash_detective": "クラッシュインスペクターを開く",
        "export_all_markdown": "すべてエクスポート (.md)",
        "export_all_clipboard": "Markdownとしてコピー",
        "clear_logs": "ログ消去",
        "filter_all": "すべて",
        "filter_errors": "エラーのみ (4xx/5xx)",
        "filter_search": "URL、メソッド、ステータスで絞り込み...",

        "settings_header": "設定＆環境設定",
        "settings_language": "表示言語",
        "settings_language_desc": "DeviceBarのインターフェース言語を選択",
        "settings_general": "一般設定",
        "settings_launch_at_login": "Macログイン時に自動起動",
        "settings_launch_at_login_desc": "ログイン時にDeviceBarをメニューバーに常駐させます",
        "settings_auto_refresh": "自動更新インターバル",
        "settings_auto_refresh_desc": "バックグラウンドでのデバイス検知頻度",
        "refresh_fast": "高速 (1.5秒)",
        "refresh_normal": "標準 (3秒)",
        "refresh_slow": "省電力 (6秒)",
        "refresh_manual": "手動のみ",
        "install_app": "/Applications にインストール",
        "install_app_desc": "DeviceBarをシステムアプリケーションフォルダにコピー",
        "open_app_folder": "/Applications フォルダを開く",

        "settings_environment": "開発ツール環境",
        "xcode_tools": "Xcode Command Line Tools",
        "android_sdk_adb": "Android SDK & ADB",
        "scrcpy_tool": "Scrcpy (画面ミラーリング)",
        "status_installed": "インストール済み",
        "status_not_found": "未検出",
        "detected_at": "パス",
        "install_guide_scrcpy": "'brew install scrcpy' を実行すると高速ミラーリングが有効になります。",

        "settings_network_inspector": "ネットワークインスペクター設定",
        "buffer_size": "ログバッファ容量",
        "buffer_size_desc": "メモリに保持する最大HTTPリクエスト数",
        "auto_capture": "バックグラウンド自動キャプチャ",
        "auto_capture_desc": "新しいトラフィックを常にリッスンします",

        "settings_about": "DeviceBar について",
        "version": "バージョン",
        "github_repo": "GitHub リポジトリ",
        "open_github": "GitHub で見る",
        "license": "ライセンス: MIT オープンソース",
        "buy_me_a_coffee": "コーヒーをご馳走",
        "support": "サポート",
        "quit_app": "DeviceBar を終了"
    ]

    // MARK: - 4. Chinese Simplified Translations (简体中文)
    private let chineseTranslations: [String: String] = [
        "tab_simulators": "模拟器与 AVD",
        "tab_physical_devices": "真机与投屏",
        "tab_tools": "快捷工具",
        "tab_settings": "设置",

        "app_title": "DeviceBar",
        "booted": "运行中",
        "refresh_tooltip": "刷新设备列表 (Cmd+R)",
        "settings_tooltip": "DeviceBar 设置与首选项",
        "ready_status": "就绪 • 设备控制器已激活",

        "search_placeholder": "按名称、iOS / API 版本搜索...",
        "filter_booted_only": "运行中",
        "filter_booted_tooltip": "仅显示正在运行的模拟器与 AVD",

        "boot": "启动",
        "shutdown": "关机",
        "erase": "抹掉内容和设置",
        "cold_boot": "冷启动 (Cold Boot)",
        "wipe_data": "清除数据 (Wipe)",
        "delete": "删除",
        "copy_id": "复制 ID",
        "confirm_delete_sim": "确定要删除此模拟器吗？",
        "confirm_erase_sim": "抹掉所有数据并重置此模拟器？",
        "confirm_wipe_avd": "清除此 Android AVD 的所有用户数据？",

        "no_physical_devices": "未检测到已连接的真机",
        "connect_device_hint": "请通过数据线连接 iPhone/iPad，或连接已开启 USB 调试的 Android 设备。",
        "start_mirroring": "启动屏幕镜像",
        "wireless_mirroring": "无线连接",
        "disconnect": "断开连接",
        "battery": "电量",

        "lan_ip_title": "局域网 IP 地址 (LAN IP)",
        "lan_ip_subtitle": "用于从手机真机访问 Mac 上的后端本地服务",
        "copy": "复制",
        "copied": "已复制",
        "storage_cleaner_title": "开发者存储空间清理",
        "storage_cleaner_subtitle": "安全清理 Xcode DerivedData、Gradle 缓存和设备日志",
        "clean_all": "一键清理所有安全缓存",
        "cleaning": "清理中...",
        "derived_data": "Xcode DerivedData",
        "gradle_cache": "Android Gradle 缓存",
        "device_support": "iOS DeviceSupport",
        "package_cache": "SwiftPM & SPM 缓存",
        "sim_logs": "模拟器日志与缓存",
        "archives": "Xcode Archives 归档",
        "media_access_title": "截图与屏幕录像",
        "media_access_subtitle": "快速访问设备捕获的媒体文件目录",
        "open_screenshots": "打开截图文件夹",
        "open_recordings": "打开录屏文件夹",
        "restart_adb": "重启 ADB 服务",
        "restart_adb_desc": "当 Android 真机无法响应时重启 ADB 守护进程",
        "restarting": "正在重启...",
        "restarted": "重启成功",

        "network_inspector_title": "网络与 API 监控器",
        "network_inspector_desc": "实时监控 HTTP/HTTPS 流量，捕获报错接口并导出 cURL",
        "open_network_inspector": "打开网络监控器",
        "crash_detective_title": "崩溃侦探 (Crash Detective)",
        "crash_detective_desc": "自动捕获应用崩溃日志并解析堆栈跟踪",
        "open_crash_detective": "打开崩溃分析器",
        "export_all_markdown": "全量导出 (.md)",
        "export_all_clipboard": "复制为 Markdown",
        "clear_logs": "清空日志",
        "filter_all": "全部",
        "filter_errors": "仅错误 (4xx/5xx)",
        "filter_search": "按 URL、方法或状态码过滤...",

        "settings_header": "设置与首选项",
        "settings_language": "界面语言",
        "settings_language_desc": "选择 DeviceBar 显示语言",
        "settings_general": "通用设置",
        "settings_launch_at_login": "开机自动启动",
        "settings_launch_at_login_desc": "登录 macOS 时自动在菜单栏启动 DeviceBar",
        "settings_auto_refresh": "设备自动刷新频率",
        "settings_auto_refresh_desc": "后台检测硬件设备与模拟器的刷新频率",
        "refresh_fast": "快速 (1.5秒)",
        "refresh_normal": "标准 (3秒)",
        "refresh_slow": "省电 (6秒)",
        "refresh_manual": "仅手动刷新",
        "install_app": "安装到 /Applications",
        "install_app_desc": "将 DeviceBar 复制到系统应用程序目录",
        "open_app_folder": "打开 /Applications 目录",

        "settings_environment": "开发工具环境",
        "xcode_tools": "Xcode 命令行工具 (simctl)",
        "android_sdk_adb": "Android SDK & ADB",
        "scrcpy_tool": "Scrcpy (投屏工具)",
        "status_installed": "已安装",
        "status_not_found": "未找到",
        "detected_at": "路径",
        "install_guide_scrcpy": "运行 'brew install scrcpy' 即可启用流畅的 60fps 投屏功能。",

        "settings_network_inspector": "网络监控器配置",
        "buffer_size": "日志缓存容量",
        "buffer_size_desc": "内存中保存的最大 HTTP 请求数量",
        "auto_capture": "后台自动捕获流量",
        "auto_capture_desc": "持续侦听移动端网络请求",

        "settings_about": "关于 DeviceBar",
        "version": "版本",
        "github_repo": "GitHub 代码仓库",
        "open_github": "在 GitHub 上查看",
        "license": "开源协议: MIT License",
        "buy_me_a_coffee": "请喝咖啡",
        "support": "支持作者",
        "quit_app": "退出 DeviceBar"
    ]

    // MARK: - 5. Korean Translations (한국어)
    private let koreanTranslations: [String: String] = [
        "tab_simulators": "시뮬레이터 & AVD",
        "tab_physical_devices": "실제 기기 & 미러링",
        "tab_tools": "빠른 도구",
        "tab_settings": "설정",

        "app_title": "DeviceBar",
        "booted": "실행 중",
        "refresh_tooltip": "기기 목록 새로고침 (Cmd+R)",
        "settings_tooltip": "DeviceBar 환경설정",
        "ready_status": "준비 완료 • 기기 제어 대기 중",

        "search_placeholder": "이름, iOS / API 버전으로 검색...",
        "filter_booted_only": "실행 중만",
        "filter_booted_tooltip": "실행 중인 시뮬레이터 및 에뮬레이터만 표시",

        "boot": "부팅",
        "shutdown": "종료",
        "erase": "콘텐츠 및 설정 지우기",
        "cold_boot": "콜드 부팅",
        "wipe_data": "데이터 초기화 (Wipe)",
        "delete": "삭제",
        "copy_id": "ID 복사",
        "confirm_delete_sim": "이 시뮬레이터를 삭제하시겠습니까?",
        "confirm_erase_sim": "모든 데이터를 지우고 시뮬레이터를 초기화하시겠습니까?",
        "confirm_wipe_avd": "이 Android AVD의 사용자 데이터를 모두 지우시겠습니까?",

        "no_physical_devices": "연결된 기기가 없습니다",
        "connect_device_hint": "iPhone/iPad를 USB로 연결하거나 USB 디버깅이 활성화된 Android를 연결하세요.",
        "start_mirroring": "화면 미러링 시작",
        "wireless_mirroring": "무선 연결",
        "disconnect": "연결 해제",
        "battery": "배터리",

        "lan_ip_title": "로컬 IP 주소 (LAN IP)",
        "lan_ip_subtitle": "실제 기기에서 Mac 백엔드 서버를 호출할 때 사용합니다",
        "copy": "복사",
        "copied": "복사됨",
        "storage_cleaner_title": "개발자 디스크 정리",
        "storage_cleaner_subtitle": "Xcode DerivedData, Gradle 캐시, 로그를 안전하게 삭제",
        "clean_all": "안전한 캐시 일괄 정리",
        "cleaning": "정리 중...",
        "derived_data": "Xcode DerivedData",
        "gradle_cache": "Android Gradle 캐시",
        "device_support": "iOS DeviceSupport",
        "package_cache": "SwiftPM & SPM 캐시",
        "sim_logs": "시뮬레이터 로그 & 캐시",
        "archives": "Xcode 아카이브",
        "media_access_title": "스크린샷 & 화면 녹화",
        "media_access_subtitle": "캡처된 미디어 폴더로 빠르게 이동",
        "open_screenshots": "스크린샷 폴더 열기",
        "open_recordings": "녹화 폴더 열기",
        "restart_adb": "ADB 서버 재시작",
        "restart_adb_desc": "Android 기기 인식이 안 될 때 ADB 데몬을 재시작합니다",
        "restarting": "재시작 중...",
        "restarted": "재시작 완료",

        "network_inspector_title": "네트워크 & API 인스펙터",
        "network_inspector_desc": "HTTP/HTTPS 트래픽 감시, 오류 캡처 및 cURL 내보내기",
        "open_network_inspector": "네트워크 인스펙터 열기",
        "crash_detective_title": "크래시 디텍티브 (Crash Detective)",
        "crash_detective_desc": "앱 충돌 감지 및 스택 추적 분석",
        "open_crash_detective": "크래시 인스펙터 열기",
        "export_all_markdown": "전체 내보내기 (.md)",
        "export_all_clipboard": "Markdown으로 복사",
        "clear_logs": "로그 지우기",
        "filter_all": "전체",
        "filter_errors": "오류만 (4xx/5xx)",
        "filter_search": "URL, 메서드, 상태 코드로 필터링...",

        "settings_header": "설정 & 환경설정",
        "settings_language": "표시 언어",
        "settings_language_desc": "DeviceBar 인터페이스 언어 선택",
        "settings_general": "일반",
        "settings_launch_at_login": "Mac 로그인 시 자동 실행",
        "settings_launch_at_login_desc": "로그인 시 메뉴 막대에 DeviceBar를 자동으로 실행합니다",
        "settings_auto_refresh": "기기 자동 새로고침 주기",
        "settings_auto_refresh_desc": "백그라운드 기기 검색 주기",
        "refresh_fast": "빠름 (1.5초)",
        "refresh_normal": "표준 (3초)",
        "refresh_slow": "절전 (6초)",
        "refresh_manual": "수동 전용",
        "install_app": "/Applications 에 설치",
        "install_app_desc": "DeviceBar를 시스템 응용 프로그램 폴더로 복사합니다",
        "open_app_folder": "/Applications 폴더 열기",

        "settings_environment": "개발 도구 환경",
        "xcode_tools": "Xcode Command Line Tools",
        "android_sdk_adb": "Android SDK & ADB",
        "scrcpy_tool": "Scrcpy (화면 미러링)",
        "status_installed": "설치됨",
        "status_not_found": "미설치",
        "detected_at": "경로",
        "install_guide_scrcpy": "'brew install scrcpy'를 실행하면 60fps 화면 미러링을 사용할 수 있습니다.",

        "settings_network_inspector": "네트워크 인스펙터 설정",
        "buffer_size": "로그 버퍼 용량",
        "buffer_size_desc": "메모리에 유지할 최대 HTTP 요청 수",
        "auto_capture": "백그라운드 자동 캡처",
        "auto_capture_desc": "새로운 모바일 네트워크 트래픽을 지속적으로 수신합니다",

        "settings_about": "DeviceBar 정보",
        "version": "버전",
        "github_repo": "GitHub 저장소",
        "open_github": "GitHub에서 보기",
        "license": "라이선스: MIT 오픈소스",
        "buy_me_a_coffee": "커피 한 잔 후원",
        "support": "후원하기",
        "quit_app": "DeviceBar 종료"
    ]

    // MARK: - 6. Spanish Translations (Español)
    private let spanishTranslations: [String: String] = [
        "tab_simulators": "Simuladores y AVD",
        "tab_physical_devices": "Dispositivos y Espejo",
        "tab_tools": "Herramientas",
        "tab_settings": "Ajustes",

        "app_title": "DeviceBar",
        "booted": "En ejecución",
        "refresh_tooltip": "Actualizar lista de dispositivos (Cmd+R)",
        "settings_tooltip": "Ajustes y Preferencias de DeviceBar",
        "ready_status": "Listo • Controlador de dispositivos activo",

        "search_placeholder": "Buscar por nombre, versión de iOS / API...",
        "filter_booted_only": "En ejecución",
        "filter_booted_tooltip": "Mostrar solo simuladores y emuladores en ejecución",

        "boot": "Iniciar",
        "shutdown": "Apagar",
        "erase": "Borrar contenidos y ajustes",
        "cold_boot": "Arranque en frío (Cold Boot)",
        "wipe_data": "Borrar datos de usuario (Wipe)",
        "delete": "Eliminar",
        "copy_id": "Copiar ID",
        "confirm_delete_sim": "¿Seguro que deseas eliminar este simulador?",
        "confirm_erase_sim": "¿Borrar todos los datos y reiniciar este simulador?",
        "confirm_wipe_avd": "¿Borrar todos los datos de usuario de este AVD Android?",

        "no_physical_devices": "No se encontraron dispositivos conectados",
        "connect_device_hint": "Conecta un iPhone/iPad por cable o un Android con depuración USB activada.",
        "start_mirroring": "Iniciar Espejo",
        "wireless_mirroring": "Conexión Wi-Fi",
        "disconnect": "Desconectar",
        "battery": "Batería",

        "lan_ip_title": "Dirección IP Local (LAN IP)",
        "lan_ip_subtitle": "Usa esta IP para llamadas backend desde dispositivos reales",
        "copy": "Copiar",
        "copied": "Copiado",
        "storage_cleaner_title": "Limpiador de Almacenamiento Dev",
        "storage_cleaner_subtitle": "Libera de forma segura DerivedData, caché Gradle y registros",
        "clean_all": "Limpiar todo el caché seguro",
        "cleaning": "Limpiando...",
        "derived_data": "Xcode DerivedData",
        "gradle_cache": "Caché Android Gradle",
        "device_support": "iOS DeviceSupport",
        "package_cache": "Caché SwiftPM y SPM",
        "sim_logs": "Registros y caché del simulador",
        "archives": "Archivos Xcode (Archives)",
        "media_access_title": "Capturas y Grabaciones",
        "media_access_subtitle": "Acceso rápido a los archivos capturados",
        "open_screenshots": "Abrir carpeta de capturas",
        "open_recordings": "Abrir carpeta de grabaciones",
        "restart_adb": "Reiniciar servidor ADB",
        "restart_adb_desc": "Reinicia el demonio ADB si los dispositivos no responden",
        "restarting": "Reiniciando...",
        "restarted": "Reiniciado",

        "network_inspector_title": "Inspector de Red y APIs",
        "network_inspector_desc": "Monitorea tráfico HTTP/HTTPS, captura errores y exporta cURL",
        "open_network_inspector": "Abrir Inspector de Red",
        "crash_detective_title": "Detective de Fallos (Crash Detective)",
        "crash_detective_desc": "Detecta cierres inesperados y examina trazas de pila",
        "open_crash_detective": "Abrir Inspector de Fallos",
        "export_all_markdown": "Exportar todo (.md)",
        "export_all_clipboard": "Copiar como Markdown",
        "clear_logs": "Limpiar registros",
        "filter_all": "Todo",
        "filter_errors": "Solo errores (4xx/5xx)",
        "filter_search": "Filtrar por URL, método o código...",

        "settings_header": "Ajustes y Preferencias",
        "settings_language": "Idioma de interfaz",
        "settings_language_desc": "Selecciona el idioma de DeviceBar",
        "settings_general": "General",
        "settings_launch_at_login": "Iniciar al arrancar macOS",
        "settings_launch_at_login_desc": "Inicia DeviceBar automáticamente al iniciar sesión",
        "settings_auto_refresh": "Intervalo de actualización automática",
        "settings_auto_refresh_desc": "Frecuencia de búsqueda de dispositivos en segundo plano",
        "refresh_fast": "Rápido (1.5s)",
        "refresh_normal": "Estándar (3s)",
        "refresh_slow": "Bajo consumo (6s)",
        "refresh_manual": "Solo manual",
        "install_app": "Instalar en /Applications",
        "install_app_desc": "Copia DeviceBar en la carpeta de Aplicaciones del sistema",
        "open_app_folder": "Abrir carpeta /Applications",

        "settings_environment": "Entorno de herramientas",
        "xcode_tools": "Herramientas de línea de órdenes Xcode",
        "android_sdk_adb": "Android SDK & ADB",
        "scrcpy_tool": "Scrcpy (Espejo de pantalla)",
        "status_installed": "Instalado",
        "status_not_found": "No encontrado",
        "detected_at": "Ruta",
        "install_guide_scrcpy": "Ejecuta 'brew install scrcpy' para habilitar el espejo a 60 fps.",

        "settings_network_inspector": "Configuración del Inspector de Red",
        "buffer_size": "Capacidad del búfer de registros",
        "buffer_size_desc": "Número máximo de peticiones HTTP en memoria",
        "auto_capture": "Captura automática en segundo plano",
        "auto_capture_desc": "Escucha continuamente nuevo tráfico de red",

        "settings_about": "Acerca de DeviceBar",
        "version": "Versión",
        "github_repo": "Repositorio GitHub",
        "open_github": "Ver en GitHub",
        "license": "Licencia: Código abierto MIT",
        "buy_me_a_coffee": "Invítame un café",
        "support": "Apoyar",
        "quit_app": "Salir de DeviceBar"
    ]
}

// Global helper function
@MainActor
public func loc(_ key: String) -> String {
    LanguageManager.shared.tr(key)
}
