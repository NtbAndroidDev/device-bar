import Foundation

public final class ShellService: @unchecked Sendable {
    public static let shared = ShellService()

    private init() {}

    /// Computes full PATH environment variable including Homebrew and Android SDK paths
    public var environment: [String: String] {
        var env = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let extraPaths = [
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/local/sbin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
            "\(home)/Library/Android/sdk/platform-tools",
            "\(home)/Library/Android/sdk/emulator",
            "\(home)/Library/Android/sdk/cmdline-tools/latest/bin",
            "\(home)/Library/Android/sdk/tools",
            "\(home)/Library/Android/sdk/tools/bin"
        ]

        let currentPath = env["PATH"] ?? ""
        let combinedPath = (extraPaths + [currentPath]).joined(separator: ":")
        env["PATH"] = combinedPath
        if env["ANDROID_HOME"] == nil {
            env["ANDROID_HOME"] = "\(home)/Library/Android/sdk"
        }
        if env["ANDROID_SDK_ROOT"] == nil {
            env["ANDROID_SDK_ROOT"] = "\(home)/Library/Android/sdk"
        }
        return env
    }

    /// Executes a shell command string using `/bin/zsh -c`
    @discardableResult
    public func run(_ command: String) async throws -> String {
        let env = self.environment
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-c", command]
                process.environment = env


                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let error = String(data: errorData, encoding: .utf8) ?? ""

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                        let combinedError = error.isEmpty ? output : error
                        continuation.resume(throwing: NSError(
                            domain: "ShellService",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: combinedError.trimmingCharacters(in: .whitespacesAndNewlines)]
                        ))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Checks if a command binary is available in PATH
    public func isCommandAvailable(_ command: String) async -> Bool {
        do {
            let result = try await run("which \(command)")
            return !result.isEmpty
        } catch {
            return false
        }
    }
}
