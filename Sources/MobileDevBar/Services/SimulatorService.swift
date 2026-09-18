import Foundation
import AppKit

public final class SimulatorService {
    public static let shared = SimulatorService()
    private let shell = ShellService.shared

    private init() {}

    // MARK: - List Devices
    public func fetchSimulators() async throws -> [SimulatorDevice] {
        let jsonString = try await shell.run("xcrun simctl list -j devices")
        guard let data = jsonString.data(using: .utf8) else { return [] }

        var results: [SimulatorDevice] = []

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let devicesByRuntime = json["devices"] as? [String: [[String: Any]]] {
            for (runtime, devices) in devicesByRuntime {
                // CHỈ LẤY CÁC SIMULATOR iOS (iPhone & iPad), bỏ qua watchOS/tvOS/xrOS rác
                guard runtime.lowercased().contains("ios") else { continue }

                for item in devices {
                    let udid = item["udid"] as? String ?? ""
                    let name = item["name"] as? String ?? "Unknown Simulator"
                    let stateString = item["state"] as? String ?? "Shutdown"
                    let isAvailable = item["isAvailable"] as? Bool ?? true

                    // Bỏ qua các simulator không khả dụng trên hệ điều hành
                    guard isAvailable else { continue }

                    let state: SimulatorDevice.State
                    switch stateString.lowercased() {
                    case "booted": state = .booted
                    case "shutdown": state = .shutdown
                    case "shutting down": state = .shuttingDown
                    default: state = .unknown
                    }

                    let device = SimulatorDevice(
                        id: udid,
                        name: name,
                        udid: udid,
                        runtime: runtime,
                        state: state,
                        isAvailable: isAvailable
                    )
                    results.append(device)
                }
            }
        }

        // Sort: Booted lên đầu tiên, sau đó theo tên
        return results.sorted {
            if $0.state.isBooted != $1.state.isBooted {
                return $0.state.isBooted && !$1.state.isBooted
            }
            return $0.name < $1.name
        }
    }


    // MARK: - Lifecycle Actions
    public func boot(udid: String) async throws {
        _ = try await shell.run("xcrun simctl boot \"\(udid)\" 2>/dev/null || true")
        _ = try await shell.run("open -a Simulator")
    }

    public func shutdown(udid: String) async throws {
        _ = try await shell.run("xcrun simctl shutdown \"\(udid)\"")
    }

    public func erase(udid: String) async throws {
        _ = try await shell.run("xcrun simctl shutdown \"\(udid)\" 2>/dev/null || true")
        _ = try await shell.run("xcrun simctl erase \"\(udid)\"")
    }

    public func killAllSimulators() async throws {
        _ = try await shell.run("killall -9 Simulator 2>/dev/null || true")
        _ = try await shell.run("xcrun simctl shutdown all 2>/dev/null || true")
    }

    // MARK: - Quick Tweaks for Booted Simulators
    public func toggleAppearance(udid: String, dark: Bool) async throws {
        let mode = dark ? "dark" : "light"
        _ = try await shell.run("xcrun simctl ui \"\(udid)\" appearance \(mode)")
    }

    public func changeLocale(udid: String, preset: LocalePreset) async throws {
        // Set AppleLanguages and AppleLocale
        _ = try await shell.run("xcrun simctl spawn \"\(udid)\" defaults write \"Apple Global Domain\" AppleLanguages '(\"\(preset.languageCode)\")'")
        _ = try await shell.run("xcrun simctl spawn \"\(udid)\" defaults write \"Apple Global Domain\" AppleLocale \"\(preset.localeIdentifier)\"")
    }

    public func triggerBiometric(udid: String, match: Bool) async throws {
        // First make sure biometrics are enrolled
        _ = try await shell.run("xcrun simctl biometric \"\(udid)\" enroll")
        let action = match ? "match" : "unmatch"
        _ = try await shell.run("xcrun simctl biometric \"\(udid)\" \(action)")
    }

    public func setLocation(udid: String, latitude: Double, longitude: Double) async throws {
        _ = try await shell.run("xcrun simctl location \"\(udid)\" set \(latitude) \(longitude)")
    }

    public func openURL(udid: String, urlString: String) async throws {
        guard let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NSError(domain: "SimulatorService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL string"])
        }
        _ = try await shell.run("xcrun simctl openurl \"\(udid)\" \"\(encodedURL)\"")
    }

    // MARK: - Capture & Clipboard
    public func captureScreenshot(
        udid: String,
        mask: ScreenshotMask = .alpha,
        saveToDesktop: Bool = false
    ) async throws -> URL {
        let targetDir: URL
        if saveToDesktop {
            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
            let folder = desktop.appendingPathComponent("MobileDevBar_Screenshots", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            targetDir = folder
        } else {
            targetDir = FileManager.default.temporaryDirectory
        }

        let fileName = "sim_\(mask.rawValue)_\(Int(Date().timeIntervalSince1970)).png"
        let fileURL = targetDir.appendingPathComponent(fileName)

        _ = try await shell.run("xcrun simctl io \"\(udid)\" screenshot --mask=\(mask.rawValue) \"\(fileURL.path)\"")

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

    // MARK: - Video Recording
    public func recordVideo(udid: String, durationSeconds: Int = 10) async throws -> URL {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let folder = desktop.appendingPathComponent("MobileDevBar_Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let fileName = "sim_record_\(Int(Date().timeIntervalSince1970)).mp4"
        let fileURL = folder.appendingPathComponent(fileName)

        // xcrun simctl io recordVideo runs until interrupt. We run background subshell with sleep and kill
        let cmd = """
        xcrun simctl io "\(udid)" recordVideo --codec=h264 "\(fileURL.path)" &
        REC_PID=$!
        sleep \(durationSeconds)
        kill -2 $REC_PID 2>/dev/null || true
        wait $REC_PID 2>/dev/null || true
        """
        _ = try await shell.run(cmd)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }

        return fileURL
    }

    // MARK: - Media & Clipboard Helpers
    public func syncClipboardMacToSimulator(udid: String) async throws {
        _ = try await shell.run("pbpaste | xcrun simctl pbcopy \"\(udid)\"")
    }

    public func syncClipboardSimulatorToMac(udid: String) async throws {
        _ = try await shell.run("xcrun simctl pbpaste \"\(udid)\" | pbcopy")
    }

    public func addSamplePhoto(udid: String) async throws {
        let tempImageURL = FileManager.default.temporaryDirectory.appendingPathComponent("sample_photo.png")
        if !FileManager.default.fileExists(atPath: tempImageURL.path) {
            let size = NSSize(width: 800, height: 800)
            let image = NSImage(size: size)
            image.lockFocus()
            let gradient = NSGradient(starting: NSColor.systemBlue, ending: NSColor.systemPurple)
            gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
            image.unlockFocus()
            if let tiff = image.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: tempImageURL)
            }
        }
        _ = try await shell.run("xcrun simctl addmedia \"\(udid)\" \"\(tempImageURL.path)\"")
    }
}


