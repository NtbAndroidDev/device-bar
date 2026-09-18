import Foundation

public final class NetworkLogParser {
    public static let shared = NetworkLogParser()
    
    private init() {}
    
    /// Phân tích một khối text logs (từ logcat hoặc console log) thành danh sách NetworkLogItem
    public func parseLines(_ lines: [String]) -> [NetworkLogItem] {
        var items: [NetworkLogItem] = []
        
        var currentMethod: String?
        var currentURL: String?
        var currentRequestHeaders: [String: String] = [:]
        var currentRequestBodyLines: [String] = []
        
        var currentStatusCode: Int?
        var currentStatusText: String?
        var currentDuration: Int?
        var currentResponseHeaders: [String: String] = [:]
        var currentResponseBodyLines: [String] = []
        var isInResponseBody = false
        
        for rawLine in lines {
            let line = cleanLine(rawLine)
            
            // 1. Nhận diện Bắt đầu Request (OkHttp format: "--> POST https://...")
            if line.contains("--> ") {
                let parts = line.components(separatedBy: "--> ")
                if parts.count >= 2 {
                    let requestPart = parts[1].trimmingCharacters(in: .whitespaces)
                    let words = requestPart.split(separator: " ")
                    if words.count >= 2 {
                        let method = String(words[0]).uppercased()
                        let possibleURL = String(words[1])
                        if isHTTPMethod(method) && possibleURL.starts(with: "http") {
                            // Lưu item trước nếu có
                            if let u = currentURL, let m = currentMethod {
                                items.append(buildItem(
                                    method: m,
                                    url: u,
                                    reqHeaders: currentRequestHeaders,
                                    reqBody: currentRequestBodyLines.joined(separator: "\n"),
                                    code: currentStatusCode,
                                    statusText: currentStatusText,
                                    duration: currentDuration,
                                    resHeaders: currentResponseHeaders,
                                    resBody: currentResponseBodyLines.joined(separator: "\n")
                                ))
                            }
                            
                            // Reset cho request mới
                            currentMethod = method
                            currentURL = possibleURL
                            currentRequestHeaders = [:]
                            currentRequestBodyLines = []
                            currentStatusCode = nil
                            currentStatusText = nil
                            currentDuration = nil
                            currentResponseHeaders = [:]
                            currentResponseBodyLines = []
                            isInResponseBody = false
                            continue
                        }
                    }
                }
            }
            
            // 2. Nhận diện Kết thúc Request ("--> END POST")
            if line.contains("--> END ") {
                continue
            }
            
            // 3. Nhận diện Response (OkHttp format: "<-- 200 OK https://... (120ms)")
            if line.contains("<-- ") {
                let parts = line.components(separatedBy: "<-- ")
                if parts.count >= 2 {
                    let resPart = parts[1].trimmingCharacters(in: .whitespaces)
                    
                    // Trường hợp HTTP FAILED
                    if resPart.contains("HTTP FAILED:") {
                        let errMsg = resPart.components(separatedBy: "HTTP FAILED:").last?.trimmingCharacters(in: .whitespaces)
                        currentStatusCode = 0
                        currentStatusText = "FAILED"
                        isInResponseBody = false
                        if let u = currentURL, let m = currentMethod {
                            items.append(NetworkLogItem(
                                method: m,
                                url: u,
                                statusCode: 0,
                                statusText: "FAILED",
                                requestHeaders: currentRequestHeaders,
                                requestBody: currentRequestBodyLines.joined(separator: "\n"),
                                isError: true,
                                errorMessage: errMsg
                            ))
                            currentURL = nil
                            currentMethod = nil
                        }
                        continue
                    }
                    
                    let words = resPart.split(separator: " ")
                    if words.count >= 2, let code = Int(words[0]) {
                        currentStatusCode = code
                        currentStatusText = String(words[1])
                        
                        // Parse duration nếu có: (142ms)
                        if let durationStr = resPart.components(separatedBy: "(").last?.components(separatedBy: "ms)").first,
                           let dur = Int(durationStr.trimmingCharacters(in: .whitespaces)) {
                            currentDuration = dur
                        }
                        
                        isInResponseBody = true
                        continue
                    }
                }
            }
            
            // 4. Nhận diện Kết thúc Response ("<-- END HTTP")
            if line.contains("<-- END HTTP") {
                isInResponseBody = false
                if let u = currentURL, let m = currentMethod {
                    items.append(buildItem(
                        method: m,
                        url: u,
                        reqHeaders: currentRequestHeaders,
                        reqBody: currentRequestBodyLines.joined(separator: "\n"),
                        code: currentStatusCode,
                        statusText: currentStatusText,
                        duration: currentDuration,
                        resHeaders: currentResponseHeaders,
                        resBody: currentResponseBodyLines.joined(separator: "\n")
                    ))
                    currentURL = nil
                    currentMethod = nil
                }
                continue
            }
            
            // 5. Parse Header hoặc Body
            if currentURL != nil {
                if isInResponseBody {
                    currentResponseBodyLines.append(line)
                } else {
                    if line.contains(":") && !line.starts(with: "{") && !line.starts(with: "[") {
                        let headerParts = line.split(separator: ":", maxSplits: 1).map(String.init)
                        if headerParts.count == 2 {
                            let key = headerParts[0].trimmingCharacters(in: .whitespaces)
                            let val = headerParts[1].trimmingCharacters(in: .whitespaces)
                            if !key.isEmpty {
                                currentRequestHeaders[key] = val
                            }
                        }
                    } else if !line.isEmpty {
                        currentRequestBodyLines.append(line)
                    }
                }
            }
            
            // 6. Nhận diện generic HTTP URL khi không có OkHttp prefix
            if line.contains("http://") || line.contains("https://") {
                if let matchedItem = parseGenericHttpLine(line) {
                    items.append(matchedItem)
                }
            }
        }
        
        // Flush item cuối
        if let u = currentURL, let m = currentMethod {
            items.append(buildItem(
                method: m,
                url: u,
                reqHeaders: currentRequestHeaders,
                reqBody: currentRequestBodyLines.joined(separator: "\n"),
                code: currentStatusCode,
                statusText: currentStatusText,
                duration: currentDuration,
                resHeaders: currentResponseHeaders,
                resBody: currentResponseBodyLines.joined(separator: "\n")
            ))
        }
        
        return items
    }
    
    private func buildItem(
        method: String,
        url: String,
        reqHeaders: [String: String],
        reqBody: String,
        code: Int?,
        statusText: String?,
        duration: Int?,
        resHeaders: [String: String],
        resBody: String
    ) -> NetworkLogItem {
        let isErr = (code ?? 200) >= 400 || (code == 0)
        return NetworkLogItem(
            method: method,
            url: url,
            statusCode: code,
            statusText: statusText ?? (isErr ? "Error" : "OK"),
            durationMs: duration,
            requestHeaders: reqHeaders,
            requestBody: reqBody.isEmpty ? nil : formatJSONIfPossible(reqBody),
            responseHeaders: resHeaders,
            responseBody: resBody.isEmpty ? nil : formatJSONIfPossible(resBody),
            isError: isErr
        )
    }
    
    private func parseGenericHttpLine(_ line: String) -> NetworkLogItem? {
        let methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD"]
        for m in methods {
            if line.contains(" \(m) ") {
                let parts = line.components(separatedBy: " \(m) ")
                if parts.count >= 2 {
                    let rest = parts[1].trimmingCharacters(in: .whitespaces)
                    let words = rest.split(separator: " ")
                    if let firstWord = words.first, firstWord.starts(with: "http") {
                        let url = String(firstWord)
                        var code: Int? = nil
                        for w in words.dropFirst() {
                            if let c = Int(w), (200...599).contains(c) {
                                code = c
                                break
                            }
                        }
                        let isErr = (code ?? 200) >= 400
                        return NetworkLogItem(
                            method: m,
                            url: url,
                            statusCode: code,
                            statusText: code != nil ? "\(code!)" : nil,
                            isError: isErr
                        )
                    }
                }
            }
        }
        return nil
    }
    
    private func cleanLine(_ line: String) -> String {
        // Cắt bỏ logcat prefix (ví dụ: "09-18 14:20:10.123 1234 5678 D OkHttp: ...")
        if let colonIndex = line.range(of: ": ") {
            let afterColon = String(line[colonIndex.upperBound...])
            return afterColon.trimmingCharacters(in: .whitespaces)
        }
        return line.trimmingCharacters(in: .whitespaces)
    }
    
    private func isHTTPMethod(_ word: String) -> Bool {
        ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"].contains(word)
    }
    
    public func formatJSONIfPossible(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8) else { return raw }
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        return raw
    }
}
