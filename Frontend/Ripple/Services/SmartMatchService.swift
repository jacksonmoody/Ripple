import Foundation

struct SmartMatchResult: Decodable {
    let phone: String?
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
}

enum SmartMatchError: Error, LocalizedError {
    case requestFailed(Int)
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .requestFailed(let code): return "SmartMatch request failed with status \(code)"
        case .serverError(let msg): return "SmartMatch error: \(msg)"
        case .decodingError: return "Failed to decode SmartMatch response"
        }
    }
}

enum SmartMatchService {

    private static var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "http://localhost:3005"
    }

    /// Batch-resolve addresses from phone numbers via the backend SmartMatch endpoint.
    /// The backend handles the TargetSmart API key and all CSV processing.
    static func resolveAddresses(
        for phones: [(id: String, phone: String)],
        authHeaders: [String: String] = [:]
    ) async throws -> [String: SmartMatchResult] {
        guard !phones.isEmpty else { return [:] }

        let url = URL(string: "\(baseURL)/api/smartmatch")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // SmartMatch can take minutes to process on TargetSmart's side
        request.timeoutInterval = 660

        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let body: [[String: String]] = phones.map { ["id": $0.id, "phone": $0.phone] }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["phones": body])

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? String {
                throw SmartMatchError.serverError(error)
            }
            throw SmartMatchError.requestFailed(statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resultsDict = json["results"] as? [String: [String: Any]] else {
            throw SmartMatchError.decodingError
        }

        var results: [String: SmartMatchResult] = [:]
        for (key, value) in resultsDict {
            results[key] = SmartMatchResult(
                phone: value["phone"] as? String,
                address: value["address"] as? String,
                city: value["city"] as? String,
                state: value["state"] as? String,
                zip: value["zip"] as? String
            )
        }
        return results
    }
}
