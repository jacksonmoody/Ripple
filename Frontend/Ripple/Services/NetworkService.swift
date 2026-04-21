import Foundation

enum NetworkService {
    private static var baseURL: String { AuthService.baseURL }

    // MARK: - Record Rallies

    struct RecordRallyContact: Encodable {
        let name: String
        let phone: String
    }

    static func recordRallies(contacts: [RecordRallyContact], token: String) async throws {
        let url = URL(string: "\(baseURL)/api/rallies")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = ["contacts": contacts.map { ["name": $0.name, "phone": $0.phone] }]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw NetworkServiceError.requestFailed
        }
    }

    // MARK: - Get User's Rallies

    struct RallyEntry: Decodable, Identifiable {
        let id: String
        let contactName: String
        let contactPhone: String
        let createdAt: String
    }

    struct ContactProfile: Decodable {
        let name: String?
        let avatarUrl: String?
        let secondDegreeCount: Int?
    }

    struct RalliesResponse: Decodable {
        let rallies: [RallyEntry]
        let total: Int
        let contactProfiles: [String: ContactProfile]?
    }

    static func getRallies(token: String) async throws -> RalliesResponse {
        let url = URL(string: "\(baseURL)/api/rallies")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw NetworkServiceError.requestFailed
        }

        return try JSONDecoder().decode(RalliesResponse.self, from: data)
    }

    // MARK: - Leaderboard

    struct LeaderboardEntryResponse: Decodable {
        let rank: Int
        let userId: String
        let name: String
        let score: Int
        let isCurrentUser: Bool
        let avatarUrl: String?
    }

    struct CurrentUserStats: Decodable {
        let rank: Int?
        let score: Int
    }

    struct LeaderboardResponse: Decodable {
        let leaderboard: [LeaderboardEntryResponse]
        let currentUser: CurrentUserStats
    }

    static func getLeaderboard(token: String) async throws -> LeaderboardResponse {
        let url = URL(string: "\(baseURL)/api/leaderboard")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw NetworkServiceError.requestFailed
        }

        return try JSONDecoder().decode(LeaderboardResponse.self, from: data)
    }

    // MARK: - Stats

    struct RecentRally: Decodable {
        let id: String
        let contactName: String
        let createdAt: String
    }

    struct ScoreBreakdown: Decodable {
        let textsPoints: Int
        let signupsPoints: Int
        let secondDegreePoints: Int
    }

    struct StatsResponse: Decodable {
        let rallyCount: Int
        let textsSent: Int
        let directSignups: Int
        let secondDegreeSignups: Int
        let score: Int
        let breakdown: ScoreBreakdown
        let totalUsersRallying: Int
        let totalRalliesNetwork: Int
        let recentRallies: [RecentRally]
    }

    static func getStats(token: String) async throws -> StatsResponse {
        let url = URL(string: "\(baseURL)/api/stats")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw NetworkServiceError.requestFailed
        }

        return try JSONDecoder().decode(StatsResponse.self, from: data)
    }
    // MARK: - Profile

    struct ProfileResponse: Decodable {
        let id: String
        let name: String?
        let email: String?
        let phoneNumber: String?
        let createdAt: String?
        let rallyCount: Int
        let uniqueContactsRallied: Int
        let firstRallyAt: String?
        let avatarUrl: String?
    }

    static func getProfile(token: String) async throws -> ProfileResponse {
        let url = URL(string: "\(baseURL)/api/profile")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw NetworkServiceError.requestFailed
        }

        return try JSONDecoder().decode(ProfileResponse.self, from: data)
    }

    struct UpdateProfileResponse: Decodable {
        let success: Bool
        let name: String?
        let email: String?
    }

    static func updateProfile(name: String? = nil, email: String? = nil, token: String) async throws -> UpdateProfileResponse {
        let url = URL(string: "\(baseURL)/api/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: String] = [:]
        if let name { body["name"] = name }
        if let email { body["email"] = email }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw NetworkServiceError.requestFailed
        }

        return try JSONDecoder().decode(UpdateProfileResponse.self, from: data)
    }
    // MARK: - Avatar

    struct AvatarUploadResponse: Decodable {
        let success: Bool
        let avatarUrl: String
    }

    static func uploadAvatar(imageData: Data, mimeType: String, token: String) async throws -> AvatarUploadResponse {
        let url = URL(string: "\(baseURL)/api/profile/avatar")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw NetworkServiceError.requestFailed
        }

        return try JSONDecoder().decode(AvatarUploadResponse.self, from: data)
    }

    static func deleteAvatar(token: String) async throws {
        let url = URL(string: "\(baseURL)/api/profile/avatar")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw NetworkServiceError.requestFailed
        }
    }

    // MARK: - Referral

    static func submitReferral(referrerId: String, token: String) async throws {
        let url = URL(string: "\(baseURL)/api/referral")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = ["referrerId": referrerId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw NetworkServiceError.requestFailed
        }
    }
}

enum NetworkServiceError: LocalizedError {
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .requestFailed: return "Request failed. Please try again."
        }
    }
}
