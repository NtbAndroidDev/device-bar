import Foundation

public struct NetworkLogItem: Identifiable, Equatable {
    public let id: String
    public let timestamp: Date
    public var method: String
    public var url: String
    public var statusCode: Int?
    public var statusText: String?
    public var durationMs: Int?
    public var requestHeaders: [String: String]
    public var requestBody: String?
    public var responseHeaders: [String: String]
    public var responseBody: String?
    public var isError: Bool
    public var errorMessage: String?
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        method: String,
        url: String,
        statusCode: Int? = nil,
        statusText: String? = nil,
        durationMs: Int? = nil,
        requestHeaders: [String: String] = [:],
        requestBody: String? = nil,
        responseHeaders: [String: String] = [:],
        responseBody: String? = nil,
        isError: Bool = false,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.statusText = statusText
        self.durationMs = durationMs
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.responseHeaders = responseHeaders
        self.responseBody = responseBody
        self.isError = isError
        self.errorMessage = errorMessage
    }
    
    /// Tạo câu lệnh cURL chuẩn từ Request để copy dán vào Postman / Terminal
    public var curlCommand: String {
        var components: [String] = ["curl -X \(method.uppercased()) '\(url)'"]
        
        for (key, val) in requestHeaders {
            components.append("-H '\(key): \(val)'")
        }
        
        if let body = requestBody, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let escapedBody = body.replacingOccurrences(of: "'", with: "'\\''")
            components.append("-d '\(escapedBody)'")
        }
        
        return components.joined(separator: " \\\n  ")
    }
    
    public var displayPath: String {
        guard let parsedURL = URL(string: url) else { return url }
        let path = parsedURL.path.isEmpty ? "/" : parsedURL.path
        if let query = parsedURL.query, !query.isEmpty {
            return "\(path)?\(query)"
        }
        return path
    }
    
    public var host: String {
        URL(string: url)?.host ?? ""
    }
}

public struct CrashReportItem: Identifiable {
    public let id: String = UUID().uuidString
    public let timestamp: Date
    public let processName: String
    public let exceptionType: String
    public let reason: String
    public let crashedThread: String?
    public let stackTrace: [String]
    public let rawLog: String
}
