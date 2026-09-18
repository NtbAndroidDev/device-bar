import Foundation
import AppKit

public final class AndroidService {
    public static let shared = AndroidService()
    private let shell = ShellService.shared

    private init() {}

    // MARK: - AVD Management
    public func fetchAVDs() async -> [AndroidAVD] {
        var avds: [AndroidAVD] = []
        do {
            let output = try await shell.run("emulator -list-avds 2>/dev/null || $ANDROID_HOME/emulator/emulator -list-avds 2>/dev/null")
            let lines = output.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            // Lấy map thực tế từ Tên AVD -> Running Serial (vd: ["Pixel_8_Pro_API_35": "emulator-5554"])
            let runningAVDMap = await fetchRunningAVDMap()

            for line in lines {
                let name = line.trimmingCharacters(in: .whitespaces)
                let serial = runningAVDMap[name]
                let isRunning = (serial != nil)

                avds.append(AndroidAVD(name: name, isRunning: isRunning, runningSerial: serial))
            }
        } catch {
            print("Failed to fetch AVDs: \(error)")
        }

        // Sắp xếp: Máy ảo đang chạy lên đầu tiên, sau đó theo tên
        return avds.sorted {
            if $0.isRunning != $1.isRunning {
                return $0.isRunning && !$1.isRunning
            }
            return $0.name < $1.name
        }
    }

    /// Lấy danh sách map từ Tên AVD thực tế sang Serial của emulator đang chạy
    private func fetchRunningAVDMap() async -> [String: String] {
        var map: [String: String] = [:]
        do {
            let output = try await shell.run("adb devices")
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.starts(with: "emulator-"), trimmed.contains("device") else { continue }
                let serial = String(trimmed.split(separator: "\t").first ?? trimmed.split(separator: " ").first ?? "").trimmingCharacters(in: .whitespaces)
                guard !serial.isEmpty else { continue }

                // 1. Cách 1: Hỏi emulator qua lệnh telnet/emu
                var avdName = try? await shell.run("adb -s \"\(serial)\" emu avd name 2>/dev/null | head -n 1")
                avdName = avdName?.trimmingCharacters(in: .whitespacesAndNewlines)

                // 2. Cách 2: Fallback qua getprop ro.boot.qemu.avd_name
                if avdName == nil || avdName?.isEmpty == true || avdName?.contains("error") == true || avdName?.contains("OK") == true {
                    avdName = try? await shell.run("adb -s \"\(serial)\" shell getprop ro.boot.qemu.avd_name 2>/dev/null")
                    avdName = avdName?.trimmingCharacters(in: .whitespacesAndNewlines)
                }

                if let name = avdName, !name.isEmpty, !name.contains("error") {
                    map[name] = serial
                }
            }
        } catch {}
        return map
    }

    public func startAVD(name: String, coldBoot: Bool = false, wipeData: Bool = false) async throws {
        var args = ["-avd", "\"\(name)\""]
        if coldBoot {
            args.append("-no-snapshot-load")
        }
        if wipeData {
            args.append("-wipe-data")
        }

        let emulatorCmd = "(emulator \(args.joined(separator: " ")) >/dev/null 2>&1 &)"
        _ = try await shell.run(emulatorCmd)
    }

    public func killAVD(serial: String) async throws {
        _ = try await shell.run("adb -s \"\(serial)\" emu kill 2>/dev/null || true")
    }

    public func killAllEmulators() async throws {
        _ = try await shell.run("killall -9 qemu-system-x86_64 2>/dev/null || true")
        _ = try await shell.run("killall -9 qemu-system-aarch64 2>/dev/null || true")
    }

    // MARK: - Physical & Connected Devices (Real Hardware Only)
    public func fetchConnectedDevices() async -> [ConnectedDevice] {
        var devices: [ConnectedDevice] = []

        // 1. Android Thiết Bị Thật qua adb (Lọc bỏ emulator-*)
        do {
            let adbOutput = try await shell.run("adb devices -l")
            let lines = adbOutput.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty,
                      !trimmed.starts(with: "List of devices"),
                      trimmed.contains("device") else { continue }

                let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
                guard let serial = parts.first.map(String.init) else { continue }

                // QUAN TRỌNG: Máy ảo emulator-* đã thuộc tab Simulators & AVD, không phải thiết bị thật
                if serial.starts(with: "emulator-") {
                    continue
                }

                let isWifi = serial.contains(":") || serial.contains(".")

                // Lấy tên hãng và model máy thật chính xác
                let brand = (try? await shell.run("adb -s \"\(serial)\" shell getprop ro.product.brand 2>/dev/null"))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                var model = (try? await shell.run("adb -s \"\(serial)\" shell getprop ro.product.model 2>/dev/null"))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if brand.isEmpty && model.isEmpty {
                    for part in parts {
                        if part.starts(with: "model:") {
                            model = part.replacingOccurrences(of: "model:", with: "").replacingOccurrences(of: "_", with: " ")
                        }
                    }
                }

                let displayName = brand.isEmpty ? (model.isEmpty ? "Android Device (\(serial))" : model) : "\(brand.capitalized) \(model)"

                devices.append(ConnectedDevice(
                    id: serial,
                    name: displayName,
                    serial: serial,
                    platform: .android,
                    connectionType: isWifi ? .wifi : .usb,
                    model: model.isEmpty ? displayName : model
                ))
            }
        } catch {}

        // 2. iOS Physical Devices via xcrun xctrace (Chỉ lấy thiết bị Online)
        do {
            let iosOutput = try await shell.run("xcrun xctrace list devices 2>/dev/null || true")
            let lines = iosOutput.components(separatedBy: .newlines)
            var inPhysicalSection = false
            for line in lines {
                if line.contains("== Devices ==") {
                    inPhysicalSection = true
                    continue
                } else if line.contains("== Devices Offline ==") || line.contains("== Simulators ==") {
                    inPhysicalSection = false
                    if line.contains("== Simulators ==") { break }
                }

                if inPhysicalSection {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, trimmed.contains("(") else { continue }
                    // Format: "B1nhhh (E88C3F1D-71E0-51EA-A4B7-298BE420894B)"
                    if let startParen = trimmed.range(of: "(", options: .backwards),
                       let endParen = trimmed.range(of: ")", options: .backwards) {
                        let udid = String(trimmed[startParen.upperBound..<endParen.lowerBound])
                        let name = String(trimmed[..<startParen.lowerBound]).trimmingCharacters(in: .whitespaces)

                        devices.append(ConnectedDevice(
                            id: udid,
                            name: name,
                            serial: udid,
                            platform: .ios,
                            connectionType: .usb,
                            model: name
                        ))
                    }
                }
            }
        } catch {}

        return devices
    }


    // MARK: - Quick Tweaks for Running Android Devices / AVDs
    public func toggleAppearance(serial: String, dark: Bool) async throws {
        _ = try await shell.run("adb -s \"\(serial)\" shell cmd uimode night \(dark ? "yes" : "no")")
    }

    public func setLocation(serial: String, latitude: Double, longitude: Double) async throws {
        // geo fix expects: geo fix <longitude> <latitude>
        _ = try? await shell.run("adb -s \"\(serial)\" emu geo fix \(longitude) \(latitude) 2>/dev/null")
        // Also broadcast mock location intent for apps listening
        _ = try? await shell.run("adb -s \"\(serial)\" shell am broadcast -a com.google.android.geo.MOCK_LOCATION --ef lat \(latitude) --ef lon \(longitude) 2>/dev/null")
    }

    public func openURL(serial: String, urlString: String) async throws {
        _ = try await shell.run("adb -s \"\(serial)\" shell am start -a android.intent.action.VIEW -d \"\(urlString)\"")
    }

    public func toggleShowTouches(serial: String, enabled: Bool) async throws {
        _ = try await shell.run("adb -s \"\(serial)\" shell settings put system show_touches \(enabled ? 1 : 0)")
    }

    public func openDevSettings(serial: String) async throws {
        _ = try await shell.run("adb -s \"\(serial)\" shell am start -a com.android.settings.APPLICATION_DEVELOPMENT_SETTINGS 2>/dev/null || true")
    }

    // MARK: - Scrcpy Screen Mirroring
    public func launchMirroring(serial: String, turnScreenOff: Bool = false) async throws {
        let isScrcpyInstalled = await shell.isCommandAvailable("scrcpy")
        guard isScrcpyInstalled else {
            throw NSError(
                domain: "AndroidService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "scrcpy chưa được cài đặt. Vui lòng chạy: brew install scrcpy"]
            )
        }

        var flags = ["--window-title \"Mirror - \(serial)\"", "--always-on-top"]
        if turnScreenOff {
            flags.append("--turn-screen-off")
        }

        let cmd = "(scrcpy -s \"\(serial)\" \(flags.joined(separator: " ")) >/dev/null 2>&1 &)"
        _ = try await shell.run(cmd)
    }

    // MARK: - Change Locale / Language
    public func changeLocale(serial: String, preset: LocalePreset) async throws {
        // Android 13+ cmd locale
        _ = try? await shell.run("adb -s \"\(serial)\" shell cmd locale set-language \(preset.languageCode) 2>/dev/null")
        _ = try? await shell.run("adb -s \"\(serial)\" shell setprop persist.sys.locale \(preset.languageCode)-\(preset.countryCode)")
    }


    // MARK: - Capture Screenshot to Clipboard & Desktop
    public func captureScreenshot(serial: String, saveToDesktop: Bool = false) async throws -> URL {
        let targetDir: URL
        if saveToDesktop {
            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
            let folder = desktop.appendingPathComponent("MobileDevBar_Screenshots", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            targetDir = folder
        } else {
            targetDir = FileManager.default.temporaryDirectory
        }

        let fileName = "android_\(serial.replacingOccurrences(of: ":", with: "_"))_\(Int(Date().timeIntervalSince1970)).png"
        let fileURL = targetDir.appendingPathComponent(fileName)

        _ = try await shell.run("adb -s \"\(serial)\" exec-out screencap -p > \"\(fileURL.path)\"")

        if let image = NSImage(contentsOf: fileURL) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }

        if saveToDesktop {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }

        return fileURL
    }

    // MARK: - Screen Recording
    public func startScreenRecord(serial: String, durationSeconds: Int = 10) async throws -> URL {
        let remotePath = "/sdcard/screenrec_\(Int(Date().timeIntervalSince1970)).mp4"
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let folder = desktop.appendingPathComponent("MobileDevBar_Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let fileName = "android_record_\(serial.replacingOccurrences(of: ":", with: "_"))_\(Int(Date().timeIntervalSince1970)).mp4"
        let localURL = folder.appendingPathComponent(fileName)

        // Record for duration
        _ = try await shell.run("adb -s \"\(serial)\" shell screenrecord --time-limit \(durationSeconds) \(remotePath)")
        // Pull to mac
        _ = try await shell.run("adb -s \"\(serial)\" pull \(remotePath) \"\(localURL.path)\"")
        // Remove from device
        _ = try await shell.run("adb -s \"\(serial)\" shell rm \(remotePath) 2>/dev/null || true")

        if FileManager.default.fileExists(atPath: localURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([localURL])
        }

        return localURL
    }

    // MARK: - Connect ADB over Wi-Fi
    public func enableWifiAdb(serial: String) async throws -> String {
        _ = try await shell.run("adb -s \"\(serial)\" tcpip 5555")
        // Get device IP
        let ipOutput = try await shell.run("adb -s \"\(serial)\" shell ip route | awk '{print $9}' | head -n 1")
        let ip = ipOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty else {
            throw NSError(domain: "AndroidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy IP của thiết bị. Hãy chắc chắn máy đã kết nối Wi-Fi cùng mạng LAN."])
        }

        let connectResult = try await shell.run("adb connect \(ip):5555")
        return "Kết nối thành công tới \(ip):5555: \(connectResult)"
    }

    // MARK: - Advanced Developer Tools
    public func triggerDevMenu(serial: String) async throws {
        _ = try await shell.run("adb -s \"\(serial)\" shell input keyevent 82")
    }

    public func pressKey(serial: String, keyCode: Int) async throws {
        _ = try await shell.run("adb -s \"\(serial)\" shell input keyevent \(keyCode)")
    }

    public func installApk(serial: String, fileURL: URL) async throws {
        _ = try await shell.run("adb -s \"\(serial)\" install -r \"\(fileURL.path)\"")
    }

    public func pushMediaFiles(serial: String, urls: [URL]) async throws {
        _ = try await shell.run("adb -s \"\(serial)\" shell mkdir -p /sdcard/Pictures/MobileDevBar")
        for url in urls {
            let dest = "/sdcard/Pictures/MobileDevBar/\(url.lastPathComponent)"
            _ = try await shell.run("adb -s \"\(serial)\" push \"\(url.path)\" \"\(dest)\"")
            _ = try await shell.run("adb -s \"\(serial)\" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d \"file://\(dest)\" 2>/dev/null || true")
        }
    }

    public func clearAppData(serial: String, packageName: String) async throws {
        let trimmed = packageName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = try await shell.run("adb -s \"\(serial)\" shell pm clear \"\(trimmed)\"")
    }
}
