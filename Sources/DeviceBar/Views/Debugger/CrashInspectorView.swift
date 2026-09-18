import SwiftUI
import AppKit

public struct CrashInspectorView: View {
    let deviceName: String
    let serial: String
    let isAndroid: Bool
    
    @State private var crashReport: CrashReportItem?
    @State private var isLoading: Bool = true
    @State private var copied: Bool = false
    
    public init(deviceName: String, serial: String, isAndroid: Bool) {
        self.deviceName = deviceName
        self.serial = serial
        self.isAndroid = isAndroid
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(Color(hex: "F43F5E"))
                        .font(.system(size: 14, weight: .bold))
                    Text("Crash Detective")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    Text("• \(deviceName)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    Task { await loadCrash() }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("Quét lại")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if let report = crashReport {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(report.rawLog, forType: .string)
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10))
                            Text(copied ? "Đã copy!" : "Copy Stack Trace")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "F43F5E"))
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Đang phân tích báo cáo Crash từ thiết bị...")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let report = crashReport {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Crash Summary Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(report.exceptionType)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: "F43F5E"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "F43F5E").opacity(0.12))
                                    .cornerRadius(6)
                                
                                Spacer()
                                
                                Text(report.processName)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(report.reason)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(8)
                        
                        // Stack Trace Header
                        Text("Stack Trace:")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        // Stack Trace Lines
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(Array(report.stackTrace.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundColor(line.contains("at ") || line.contains("0x") ? Color(hex: "E2E8F0") : Color(hex: "94A3B8"))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(12)
                        .background(Color(hex: "0D1117"))
                        .cornerRadius(8)
                    }
                    .padding(14)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "10B981"))
                    Text("Không phát hiện lỗi văng app (Crash) nào gần đây")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text("Ứng dụng đang hoạt động ổn định trên \(deviceName).")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 640, minHeight: 440)
        .task {
            await loadCrash()
        }
    }
    
    private func loadCrash() async {
        isLoading = true
        crashReport = try? await CrashInspectorService.shared.fetchRecentCrash(serial: serial, isAndroid: isAndroid)
        isLoading = false
    }
}
