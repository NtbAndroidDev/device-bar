import Foundation

// MARK: - iOS Simulator Model
public struct SimulatorDevice: Identifiable, Hashable {
    public let id: String // UDID
    public let name: String
    public let udid: String
    public let runtime: String
    public var state: State
    public let isAvailable: Bool

    public enum State: String, Codable {
        case booted = "Booted"
        case booting = "Booting"
        case shutdown = "Shutdown"
        case shuttingDown = "Shutting Down"
        case unknown = "Unknown"

        public var isBooted: Bool {
            return self == .booted
        }

        public var isProgressOrActive: Bool {
            return self == .booted || self == .booting || self == .shuttingDown
        }
    }

    public var isProgressOrActive: Bool {
        return state.isProgressOrActive
    }

    public var displayName: String {
        return name
    }

    public var osVersion: String {
        // e.g. "com.apple.CoreSimulator.SimRuntime.iOS-17-4" -> "iOS 17.4"
        if let last = runtime.components(separatedBy: ".").last {
            return last.replacingOccurrences(of: "-", with: " ")
        }
        return runtime
    }
}

// MARK: - Android AVD Model
public struct AndroidAVD: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public var isRunning: Bool
    public var runningSerial: String? // e.g. "emulator-5554"
}

// MARK: - Connected Physical Device Model
public struct ConnectedDevice: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let serial: String
    public let platform: Platform
    public let connectionType: ConnectionType
    public let model: String
    public var ipAddress: String?

    public enum Platform: String, CaseIterable {
        case android = "Android"
        case ios = "iOS"

        public var iconName: String {
            switch self {
            case .android: return "phone.fill"
            case .ios: return "iphone"
            }
        }
    }

    public enum ConnectionType: String {
        case usb = "USB"
        case wifi = "Wi-Fi"

        public var iconName: String {
            switch self {
            case .usb: return "cable.connector"
            case .wifi: return "wifi"
            }
        }
    }
}

// MARK: - Location Preset
public struct LocationPreset: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let latitude: Double
    public let longitude: Double

    public static let defaults: [LocationPreset] = [
        LocationPreset(name: "Hà Nội, Vietnam", latitude: 21.028511, longitude: 105.854167),
        LocationPreset(name: "TP. Hồ Chí Minh, Vietnam", latitude: 10.823099, longitude: 106.629664),
        LocationPreset(name: "Đà Nẵng, Vietnam", latitude: 16.054407, longitude: 108.202167),
        LocationPreset(name: "San Francisco (Apple HQ / Silicon Valley)", latitude: 37.3346, longitude: -122.0090),
        LocationPreset(name: "Tokyo, Japan", latitude: 35.6762, longitude: 139.6503),
        LocationPreset(name: "London, UK", latitude: 51.5074, longitude: -0.1278),
        LocationPreset(name: "New York, USA", latitude: 40.7128, longitude: -74.0060),
        LocationPreset(name: "Singapore", latitude: 1.3521, longitude: 103.8198)
    ]
}

// MARK: - Locale & Language Preset
public struct LocalePreset: Identifiable, Hashable {
    public var id: String { languageCode + "_" + countryCode }
    public let name: String
    public let languageCode: String
    public let countryCode: String

    public var localeIdentifier: String {
        "\(languageCode)_\(countryCode)"
    }

    public static let defaults: [LocalePreset] = [
        LocalePreset(name: "Tiếng Việt (vi_VN)", languageCode: "vi", countryCode: "VN"),
        LocalePreset(name: "English (US) (en_US)", languageCode: "en", countryCode: "US"),
        LocalePreset(name: "English (UK) (en_GB)", languageCode: "en", countryCode: "GB"),
        LocalePreset(name: "日本語 (ja_JP)", languageCode: "ja", countryCode: "JP"),
        LocalePreset(name: "한국어 (ko_KR)", languageCode: "ko", countryCode: "KR"),
        LocalePreset(name: "简体中文 (zh_CN)", languageCode: "zh-Hans", countryCode: "CN"),
        LocalePreset(name: "Français (fr_FR)", languageCode: "fr", countryCode: "FR"),
        LocalePreset(name: "Deutsch (de_DE)", languageCode: "de", countryCode: "DE")
    ]
}

// MARK: - Screenshot Mask
public enum ScreenshotMask: String, CaseIterable, Identifiable {
    case alpha = "alpha"      // Bo góc không nền (Transparent background)
    case ignored = "ignored"  // Vuông vức nguyên bản
    case black = "black"      // Nền đen

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .alpha: return "Không nền (Alpha PNG)"
        case .ignored: return "Hình chữ nhật (Ignored)"
        case .black: return "Nền đen (Black)"
        }
    }
}

