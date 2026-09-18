import Foundation

public final class CrashInspectorService {
    public static let shared = CrashInspectorService()
    private let shell = ShellService.shared
    
    private init() {}
    
    /// Lấy báo cáo Crash gần nhất từ thiết bị
    public func fetchRecentCrash(serial: String, isAndroid: Bool) async throws -> CrashReportItem? {
        if isAndroid {
            return try await fetchAndroidCrash(serial: serial)
        } else {
            return try await fetchSimulatorCrash(udid: serial)
        }
    }
    
    private func fetchAndroidCrash(serial: String) async throws -> CrashReportItem? {
        // Lấy log từ crash buffer hoặc FATAL EXCEPTION
        let output = (try? await shell.run("adb -s \"\(serial)\" logcat -b crash -d -t 200 2>/dev/null")) ?? ""
        var crashText = output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if crashText.isEmpty {
            // Thử tìm trong main logcat
            let fallback = (try? await shell.run("adb -s \"\(serial)\" logcat -d -t 500 | grep -A 30 'FATAL EXCEPTION' | tail -n 35")) ?? ""
            crashText = fallback.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !crashText.isEmpty else { return nil }
        
        var processName = "Android App"
        var exceptionType = "Fatal Exception"
        var reason = "App bị buộc dừng do lỗi chưa được bắt (Uncaught Exception)"
        var stackTrace: [String] = []
        
        let lines = crashText.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("Process: ") {
                processName = trimmed.components(separatedBy: "Process: ").last?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? processName
            } else if trimmed.contains("FATAL EXCEPTION:") {
                exceptionType = "FATAL EXCEPTION"
            } else if trimmed.contains("Exception:") || trimmed.contains("Error:") {
                if let colon = trimmed.range(of: ":") {
                    let typePart = String(trimmed[..<colon.lowerBound]).components(separatedBy: " ").last ?? "Exception"
                    exceptionType = typePart
                    reason = String(trimmed[colon.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
            } else if trimmed.contains("at ") {
                stackTrace.append(trimmed)
            }
        }
        
        return CrashReportItem(
            timestamp: Date(),
            processName: processName,
            exceptionType: exceptionType,
            reason: reason,
            crashedThread: "Main Thread",
            stackTrace: stackTrace,
            rawLog: crashText
        )
    }
    
    private func fetchSimulatorCrash(udid: String) async throws -> CrashReportItem? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let reportsDir = "\(home)/Library/Logs/DiagnosticReports"
        
        // Tìm file ips / crash mới nhất trong 10 phút gần đây
        let findCmd = "ls -t \"\(reportsDir)\" | head -n 5"
        guard let filesOutput = try? await shell.run(findCmd) else { return nil }
        let fileNames = filesOutput.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        for file in fileNames {
            let fullPath = "\(reportsDir)/\(file)"
            if let content = try? String(contentsOfFile: fullPath, encoding: .utf8) {
                if content.contains(udid) || content.contains("CoreSimulator") || content.contains("Exception Type") {
                    var process = file
                    var exType = "EXC_CRASH"
                    var reason = "Ứng dụng iOS bị dừng đột ngột (Crash)"
                    var traces: [String] = []
                    
                    let lines = content.components(separatedBy: "\n")
                    for line in lines.prefix(120) {
                        if line.starts(with: "Process:") {
                            process = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? process
                        } else if line.starts(with: "Exception Type:") {
                            exType = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? exType
                        } else if line.starts(with: "Termination Reason:") || line.starts(with: "Exception Note:") {
                            reason = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? reason
                        } else if line.contains("0x") && (line.contains("+") || line.contains("dyld") || line.contains("UIKitCore")) {
                            traces.append(line.trimmingCharacters(in: .whitespaces))
                        }
                    }
                    
                    return CrashReportItem(
                        timestamp: Date(),
                        processName: process,
                        exceptionType: exType,
                        reason: reason,
                        crashedThread: "Thread 0 Crashed",
                        stackTrace: Array(traces.prefix(25)),
                        rawLog: lines.prefix(80).joined(separator: "\n")
                    )
                }
            }
        }
        
        return nil
    }
}
