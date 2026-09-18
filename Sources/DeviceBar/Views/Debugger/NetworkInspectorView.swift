import SwiftUI
import AppKit

public struct NetworkInspectorView: View {
    let deviceName: String
    let serial: String
    let isAndroid: Bool
    
    @State private var networkItems: [NetworkLogItem] = []
    @State private var selectedItem: NetworkLogItem?
    @State private var filterText: String = ""
    @State private var onlyErrors: Bool = false
    @State private var isPaused: Bool = false
    @State private var timer: Timer? = nil
    @State private var copiedFeedback: String? = nil
    @State private var selectedDetailTab: DetailTab = .curl
    
    enum DetailTab: String, CaseIterable {
        case curl = "cURL Command"
        case request = "Request"
        case response = "Response"
    }
    
    public init(deviceName: String, serial: String, isAndroid: Bool) {
        self.deviceName = deviceName
        self.serial = serial
        self.isAndroid = isAndroid
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            topToolbar
            
            Divider()
            
            // Filter Bar
            filterBar
            
            Divider()
            
            // Master-Detail Split View
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                HSplitView {
                    // Left: Request List
                    requestListView
                        .frame(minWidth: 320, maxWidth: 420)
                    
                    // Right: Inspector Detail View
                    if let item = selectedItem {
                        detailInspectorView(for: item)
                            .frame(minWidth: 420)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Chọn một request ở danh sách bên trái để soi chi tiết")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    }
                }
            }
            
            Divider()
            
            // Bottom Status Bar
            bottomStatusBar
        }
        .frame(minWidth: 880, minHeight: 560)
        .onAppear {
            fetchInitialLogs()
            startPolling()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // MARK: - Top Toolbar
    private var topToolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: isAndroid ? "network" : "antenna.radiowaves.left.and.right")
                    .foregroundColor(Color(hex: "3B82F6"))
                    .font(.system(size: 14, weight: .bold))
                Text("API & Network Inspector")
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                
                Text("• \(deviceName)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Live indicator
            HStack(spacing: 5) {
                Circle()
                    .fill(isPaused ? Color.secondary : Color(hex: "10B981"))
                    .frame(width: 6, height: 6)
                Text(isPaused ? "Paused" : "Live Streaming")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(isPaused ? .secondary : Color(hex: "10B981"))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background((isPaused ? Color.secondary : Color(hex: "10B981")).opacity(0.12))
            .clipShape(Capsule())
            
            // Export Markdown Menu
            Menu {
                Section("Lưu File Markdown (.md)") {
                    Button {
                        exportMarkdownToFile(items: networkItems)
                    } label: {
                        Label("Xuất toàn bộ (\(networkItems.count) requests)...", systemImage: "arrow.down.doc")
                    }
                    .disabled(networkItems.isEmpty)

                    Button {
                        exportMarkdownToFile(items: networkItems.filter { $0.isError })
                    } label: {
                        Label("Chỉ xuất các API Lỗi (\(networkItems.filter { $0.isError }.count) lỗi)...", systemImage: "exclamationmark.triangle")
                    }
                    .disabled(!networkItems.contains(where: { $0.isError }))
                }

                Section("Copy vào Clipboard") {
                    Button {
                        copyMarkdownToClipboard(items: networkItems)
                    } label: {
                        Label("Copy toàn bộ báo cáo Markdown", systemImage: "doc.on.doc")
                    }
                    .disabled(networkItems.isEmpty)

                    Button {
                        copyMarkdownToClipboard(items: networkItems.filter { $0.isError })
                    } label: {
                        Label("Chỉ copy các API Lỗi", systemImage: "doc.on.doc.fill")
                    }
                    .disabled(!networkItems.contains(where: { $0.isError }))
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 10))
                    Text("Xuất .md")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "0284C7"))
            .controlSize(.small)
            .help("Xuất toàn bộ lịch sử API sang file Markdown (.md) kèm cURL, Headers & Body")

            // Pause / Resume
            Button {
                isPaused.toggle()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 10))
                    Text(isPaused ? "Tiếp tục" : "Tạm dừng")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Clear
            Button {
                networkItems.removeAll()
                selectedItem = nil
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Xoá toàn bộ lịch sử API")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        HStack(spacing: 12) {
            // Search Input
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                TextField("Lọc theo URL, endpoint, query param...", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !filterText.isEmpty {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(6)
            
            // Errors Only Toggle
            Button {
                onlyErrors.toggle()
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(onlyErrors ? Color(hex: "F43F5E") : Color.secondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                    Text("Chỉ API lỗi (4xx, 5xx)")
                        .font(.system(size: 11, weight: onlyErrors ? .semibold : .medium, design: .rounded))
                        .foregroundColor(onlyErrors ? Color(hex: "F43F5E") : .secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4.5)
                .background(onlyErrors ? Color(hex: "F43F5E").opacity(0.12) : Color.primary.opacity(0.04))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("\(filteredItems.count) requests")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Request List View
    private var requestListView: some View {
        ScrollView {
            LazyVStack(spacing: 3) {
                ForEach(filteredItems) { item in
                    let isSelected = selectedItem?.id == item.id
                    HStack(spacing: 8) {
                        // Method Badge
                        Text(item.method)
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(methodColor(item.method))
                            .frame(width: 46, alignment: .leading)
                        
                        // Status Badge
                        if let code = item.statusCode {
                            Text("\(code)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(statusColor(code))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(statusColor(code).opacity(0.12))
                                .cornerRadius(4)
                        } else {
                            Text("...")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        // Path & Host
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.displayPath)
                                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                .foregroundColor(item.isError ? Color(hex: "F43F5E") : .primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Text(item.host)
                                .font(.system(size: 9.5, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Duration
                        if let dur = item.durationMs {
                            Text("\(dur)ms")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isSelected ? Color(hex: "3B82F6").opacity(0.15) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(isSelected ? Color(hex: "3B82F6").opacity(0.4) : Color.clear, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItem = item
                    }
                }
            }
            .padding(6)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Detail Inspector View
    private func detailInspectorView(for item: NetworkLogItem) -> some View {
        VStack(spacing: 0) {
            // Action Header: Copy cURL, Copy Response JSON
            HStack(spacing: 8) {
                // Method & URL Banner
                HStack(spacing: 6) {
                    Text(item.method)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(methodColor(item.method))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(methodColor(item.method).opacity(0.12))
                        .cornerRadius(4)
                    
                    Text(item.url)
                        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                // Copy Feedback Toast
                if let feedback = copiedFeedback {
                    Text(feedback)
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "10B981"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "10B981").opacity(0.12))
                        .cornerRadius(4)
                }
                
                // Copy cURL Button (Chuẩn nhất cho Developer)
                Button {
                    copyToClipboard(text: item.curlCommand, feedback: "Đã copy cURL!")
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 9.5))
                        Text("Copy as cURL")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("Sao chép toàn bộ lệnh cURL chuẩn để dán vào Postman / Terminal")

                // Copy single request Markdown Button
                Button {
                    copyMarkdownToClipboard(items: [item])
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 9.5))
                        Text("Copy .md")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Sao chép chi tiết request này dưới định dạng Markdown (.md)")
                
                // Copy Response Button
                if let res = item.responseBody, !res.isEmpty {
                    Button {
                        copyToClipboard(text: res, feedback: "Đã copy Response!")
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9.5))
                            Text("Copy JSON")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
            
            Divider()
            
            // Tab Selector: cURL | Request | Response
            Picker("", selection: $selectedDetailTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch selectedDetailTab {
                    case .curl:
                        VStack(alignment: .leading, spacing: 6) {
                            Text("cURL Command:")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text(item.curlCommand)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(hex: "38BDF8"))
                                .textSelection(.enabled)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(hex: "0D1117"))
                                .cornerRadius(6)
                        }
                        
                    case .request:
                        VStack(alignment: .leading, spacing: 10) {
                            // Headers
                            if !item.requestHeaders.isEmpty {
                                Text("Request Headers (\(item.requestHeaders.count)):")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    ForEach(Array(item.requestHeaders.keys.sorted()), id: \.self) { key in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text(key + ":")
                                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                                .foregroundColor(Color(hex: "94A3B8"))
                                                .frame(width: 140, alignment: .leading)
                                            Text(item.requestHeaders[key] ?? "")
                                                .font(.system(size: 10.5, design: .monospaced))
                                                .foregroundColor(.primary)
                                                .textSelection(.enabled)
                                        }
                                    }
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.03))
                                .cornerRadius(6)
                            }
                            
                            // Body
                            Text("Request Body:")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            if let body = item.requestBody, !body.isEmpty {
                                Text(body)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color(hex: "E2E8F0"))
                                    .textSelection(.enabled)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(hex: "0D1117"))
                                    .cornerRadius(6)
                            } else {
                                Text("(Trống - Không có body)")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                    case .response:
                        VStack(alignment: .leading, spacing: 10) {
                            // Status Banner
                            if let code = item.statusCode {
                                HStack(spacing: 6) {
                                    Text("\(code) \(item.statusText ?? "")")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(statusColor(code))
                                    
                                    if let dur = item.durationMs {
                                        Text("• \(dur) ms")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(code).opacity(0.12))
                                .cornerRadius(5)
                            }
                            
                            // Error message if any
                            if let err = item.errorMessage {
                                Text("Lỗi kết nối: \(err)")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(hex: "F43F5E"))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(hex: "F43F5E").opacity(0.1))
                                    .cornerRadius(6)
                            }
                            
                            // Response Body
                            Text("Response Body:")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            if let res = item.responseBody, !res.isEmpty {
                                Text(res)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(item.isError ? Color(hex: "F87171") : Color(hex: "34D399"))
                                    .textSelection(.enabled)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(hex: "0D1117"))
                                    .cornerRadius(6)
                            } else {
                                Text("(Trống - Không có response body)")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "3B82F6").opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "network")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "3B82F6"))
            }
            
            VStack(spacing: 4) {
                Text("Đang lắng nghe cuộc gọi API từ \(deviceName)...")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text("Mở app trên máy ảo và thao tác để bắt ngay Request, Response và cURL tại đây.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Bottom Status Bar
    private var bottomStatusBar: some View {
        HStack(spacing: 8) {
            Text("Tip: Nhấn nút [Copy as cURL] để dán trực tiếp vào Postman hoặc Terminal.")
                .font(.system(size: 10.5, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Auto Parse: OkHttp, Retrofit, Dio, HTTP 200/400/500")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.02))
    }
    
    // MARK: - Helpers
    private var filteredItems: [NetworkLogItem] {
        networkItems.filter { item in
            if onlyErrors && !item.isError {
                return false
            }
            if filterText.isEmpty { return true }
            return item.url.localizedCaseInsensitiveContains(filterText) ||
                item.method.localizedCaseInsensitiveContains(filterText) ||
                (item.statusText?.localizedCaseInsensitiveContains(filterText) ?? false)
        }
    }
    
    private func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return Color(hex: "38BDF8")
        case "POST": return Color(hex: "34D399")
        case "PUT": return Color(hex: "FBBF24")
        case "DELETE": return Color(hex: "F87171")
        default: return Color(hex: "A78BFA")
        }
    }
    
    private func statusColor(_ code: Int) -> Color {
        if code >= 200 && code < 300 {
            return Color(hex: "10B981")
        } else if code >= 400 && code < 500 {
            return Color(hex: "F59E0B")
        } else if code >= 500 || code == 0 {
            return Color(hex: "F43F5E")
        }
        return Color(hex: "38BDF8")
    }
    
    private func copyToClipboard(text: String, feedback: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation {
            copiedFeedback = feedback
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedFeedback = nil
            }
        }
    }

    // MARK: - Export Markdown (.md)
    private func generateMarkdown(items: [NetworkLogItem]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = formatter.string(from: Date())

        let totalCount = items.count
        let errorCount = items.filter { $0.isError }.count
        let successCount = totalCount - errorCount

        var md = """
        # 📊 Báo Cáo API Network — \(deviceName)
        - **Thời gian xuất:** `\(dateStr)`
        - **Thiết bị:** `\(deviceName)` (`\(serial)`)
        - **Tổng số Request:** `\(totalCount)`
        - **Thành công (2xx):** `\(successCount)`
        - **Lỗi (4xx, 5xx, Failed):** `\(errorCount)`

        ---

        ## 📋 Bảng Danh Sách Cuộc Gọi API

        | # | Method | Status | Duration | Endpoint / URL |
        | :-: | :---: | :---: | :---: | :--- |

        """

        for (index, item) in items.enumerated() {
            let statusText = item.statusCode != nil ? "\(item.statusCode!) \(item.statusText ?? "")" : "Pending"
            let duration = item.durationMs != nil ? "\(item.durationMs!)ms" : "-"
            md += "| \(index + 1) | `\(item.method)` | \(statusText) | \(duration) | `\(item.url)` |\n"
        }

        md += "\n---\n\n## 🔍 Chi Tiết Từng Request (cURL, Headers & Body)\n\n"

        for (index, item) in items.enumerated() {
            let statusBadge = item.isError ? "🔴 LỖI" : "🟢 THÀNH CÔNG"
            let statusStr = item.statusCode != nil ? "\(item.statusCode!) \(item.statusText ?? "")" : "Pending"
            let durStr = item.durationMs != nil ? "\(item.durationMs!) ms" : "-"

            md += """
            ### \(index + 1). [\(item.method)] \(statusStr) — \(statusBadge)
            - **URL:** `\(item.url)`
            - **Thời gian phản hồi:** `\(durStr)`

            #### 💻 Lệnh cURL (Sao chép dán vào Postman / Terminal):
            ```bash
            \(item.curlCommand)
            ```

            """

            if !item.requestHeaders.isEmpty {
                md += "#### 📤 Request Headers:\n```http\n"
                for (k, v) in item.requestHeaders.sorted(by: { $0.key < $1.key }) {
                    md += "\(k): \(v)\n"
                }
                md += "```\n\n"
            }

            if let reqBody = item.requestBody, !reqBody.isEmpty {
                md += "#### 📦 Request Body:\n```json\n\(reqBody)\n```\n\n"
            }

            if let err = item.errorMessage {
                md += "#### ⚠️ Lỗi Kết Nối:\n```text\n\(err)\n```\n\n"
            }

            if !item.responseHeaders.isEmpty {
                md += "#### 📥 Response Headers:\n```http\n"
                for (k, v) in item.responseHeaders.sorted(by: { $0.key < $1.key }) {
                    md += "\(k): \(v)\n"
                }
                md += "```\n\n"
            }

            if let resBody = item.responseBody, !resBody.isEmpty {
                md += "#### 📬 Response Body:\n```json\n\(resBody)\n```\n\n"
            }

            md += "---\n\n"
        }

        return md
    }

    private func exportMarkdownToFile(items: [NetworkLogItem]) {
        let mdContent = generateMarkdown(items: items)

        let savePanel = NSSavePanel()
        savePanel.title = "Xuất Báo Cáo API Markdown (.md)"
        savePanel.prompt = "Xuất File"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let cleanName = deviceName.replacingOccurrences(of: " ", with: "_")
        savePanel.nameFieldStringValue = "API_Report_\(cleanName)_\(timestamp).md"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try mdContent.write(to: url, atomically: true, encoding: .utf8)
                copyToClipboard(text: "", feedback: "Đã xuất file .md thành công!")
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } catch {
                print("Lỗi lưu file: \(error)")
            }
        }
    }

    private func copyMarkdownToClipboard(items: [NetworkLogItem]) {
        let mdContent = generateMarkdown(items: items)
        copyToClipboard(text: mdContent, feedback: "Đã copy toàn bộ báo cáo Markdown!")
    }
    
    private func fetchInitialLogs() {
        Task {
            let cmd: String
            if isAndroid {
                cmd = "adb -s \"\(serial)\" logcat -d -t 400 2>/dev/null"
            } else {
                cmd = "xcrun simctl spawn \"\(serial)\" log show --last 3m --style compact 2>/dev/null | tail -n 300"
            }
            if let output = try? await ShellService.shared.run(cmd) {
                let lines = output.components(separatedBy: "\n")
                let parsed = NetworkLogParser.shared.parseLines(lines)
                await MainActor.run {
                    self.networkItems = parsed
                    if self.selectedItem == nil {
                        self.selectedItem = parsed.last
                    }
                }
            }
        }
    }
    
    private func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            Task { @MainActor in
                guard !self.isPaused else { return }
                let cmd: String
                if isAndroid {
                    cmd = "adb -s \"\(serial)\" logcat -d -t 60 2>/dev/null"
                } else {
                    cmd = "xcrun simctl spawn \"\(serial)\" log show --last 4s --style compact 2>/dev/null | tail -n 60"
                }
                if let output = try? await ShellService.shared.run(cmd) {
                    let lines = output.components(separatedBy: "\n")
                    let freshItems = NetworkLogParser.shared.parseLines(lines)
                    let existingURLs = Set(self.networkItems.suffix(30).map { $0.url + ($0.method) })
                    let newUnique = freshItems.filter { !existingURLs.contains($0.url + $0.method) }
                    if !newUnique.isEmpty {
                        self.networkItems.append(contentsOf: newUnique)
                        if self.networkItems.count > 500 {
                            self.networkItems.removeFirst(self.networkItems.count - 500)
                        }
                    }
                }
            }
        }
    }
}
