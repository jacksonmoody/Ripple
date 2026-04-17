import Foundation

struct SmartMatchResult {
    let phone: String
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
}

enum SmartMatchError: Error, LocalizedError {
    case missingAPIKey
    case registrationFailed(String)
    case uploadFailed(Int)
    case pollTimeout
    case downloadFailed
    case parseError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "TargetSmart API key not configured"
        case .registrationFailed(let msg): return "SmartMatch registration failed: \(msg)"
        case .uploadFailed(let code): return "CSV upload failed with status \(code)"
        case .pollTimeout: return "SmartMatch poll timed out"
        case .downloadFailed: return "Failed to download SmartMatch results"
        case .parseError: return "Failed to parse SmartMatch results"
        }
    }
}

enum SmartMatchService {

    private static let endpoint = "https://api.targetsmart.com/service/smartmatch"
    private static let pollEndpoint = "https://api.targetsmart.com/service/smartmatch/poll"
    private static let pollInterval: TimeInterval = 30
    private static let maxPollAttempts = 20 // 10 minutes max

    static var apiKey: String? {
        ProcessInfo.processInfo.environment["TS_API_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "TS_API_KEY") as? String
    }

    // MARK: - Public

    /// Batch-resolve addresses from phone numbers via TargetSmart SmartMatch.
    /// - Parameter phones: Array of (contactID, phoneNumber) pairs.
    /// - Returns: Dictionary keyed by phone number with SmartMatchResult values.
    static func resolveAddresses(for phones: [(id: String, phone: String)]) async throws -> [String: SmartMatchResult] {
        guard let key = apiKey, !key.isEmpty else { throw SmartMatchError.missingAPIKey }
        guard !phones.isEmpty else { return [:] }

        let filename = "ripple_\(Int(Date().timeIntervalSince1970))"
        let csv = buildCSV(from: phones)

        // Step 1: Register and get presigned upload URL
        let uploadURL = try await register(filename: filename, apiKey: key)

        // Step 2: Upload CSV
        try await uploadCSV(csv, to: uploadURL)

        // Step 3: Poll for results
        let resultsCSV = try await pollForResults(filename: filename, apiKey: key)

        // Step 4: Parse results
        return parseResults(resultsCSV)
    }

    // MARK: - CSV Building

    private static func buildCSV(from phones: [(id: String, phone: String)]) -> Data {
        var lines = ["matchback_id,phone"]
        for entry in phones {
            let digits = entry.phone.filter(\.isNumber)
            lines.append("\(entry.id),\(digits)")
        }
        return lines.joined(separator: "\n").data(using: .utf8)!
    }

    // MARK: - API Calls

    private static func register(filename: String, apiKey: String) async throws -> URL {
        var components = URLComponents(string: endpoint)!
        components.queryItems = [URLQueryItem(name: "filename", value: filename)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlString = json["url"] as? String,
              let url = URL(string: urlString) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "unknown"
            throw SmartMatchError.registrationFailed(errorMsg)
        }

        if let error = json["error"] as? String, !error.isEmpty {
            throw SmartMatchError.registrationFailed(error)
        }

        return url
    }

    private static func uploadCSV(_ csv: Data, to url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("", forHTTPHeaderField: "Content-Type")
        request.httpBody = csv

        let (_, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard statusCode == 200 else {
            throw SmartMatchError.uploadFailed(statusCode)
        }
    }

    private static func pollForResults(filename: String, apiKey: String) async throws -> String {
        var components = URLComponents(string: pollEndpoint)!
        components.queryItems = [URLQueryItem(name: "filename", value: filename)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        for _ in 0..<maxPollAttempts {
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))

            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            if let urlString = json["url"] as? String, !urlString.isEmpty,
               let downloadURL = URL(string: urlString) {
                return try await downloadResults(from: downloadURL)
            }
        }

        throw SmartMatchError.pollTimeout
    }

    private static func downloadResults(from url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let csv = String(data: data, encoding: .utf8) else {
            throw SmartMatchError.downloadFailed
        }
        return csv
    }

    // MARK: - CSV Parsing

    private static func parseResults(_ csv: String) -> [String: SmartMatchResult] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return [:] }

        let header = parseCSVLine(lines[0]).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        let phoneIdx = header.firstIndex(of: "phone")
        let matchbackIdx = header.firstIndex(of: "matchback_id")
        let addressIdx = header.firstIndex(of: "vb.regaddress")
            ?? header.firstIndex(of: "address1")
            ?? header.firstIndex(of: "vb.regaddr")
        let cityIdx = header.firstIndex(of: "vb.regcity")
            ?? header.firstIndex(of: "city")
        let stateIdx = header.firstIndex(of: "vb.regstate")
            ?? header.firstIndex(of: "vb.regstatecode")
            ?? header.firstIndex(of: "state")
        let zipIdx = header.firstIndex(of: "vb.regzip")
            ?? header.firstIndex(of: "zip")

        var results: [String: SmartMatchResult] = [:]

        for i in 1..<lines.count {
            let fields = parseCSVLine(lines[i])
            let phone = phoneIdx.flatMap { $0 < fields.count ? fields[$0] : nil } ?? ""
            let key = matchbackIdx.flatMap { $0 < fields.count ? fields[$0] : nil } ?? phone

            guard !key.isEmpty else { continue }

            let address = addressIdx.flatMap { $0 < fields.count ? fields[$0] : nil }
            let city = cityIdx.flatMap { $0 < fields.count ? fields[$0] : nil }
            let state = stateIdx.flatMap { $0 < fields.count ? fields[$0] : nil }
            let zip = zipIdx.flatMap { $0 < fields.count ? fields[$0] : nil }

            // Only store if we got at least a state
            if let st = state, !st.isEmpty {
                results[key] = SmartMatchResult(
                    phone: phone,
                    address: address,
                    city: city,
                    state: st,
                    zip: zip
                )
            }
        }

        return results
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }
}
