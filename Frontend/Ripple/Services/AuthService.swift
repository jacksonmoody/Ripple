import Foundation

struct AuthService {
    static let baseURL = "https://sway-ripple-backend.vercel.app"

    struct SendOTPResponse: Decodable {
        let success: Bool?
    }

    struct VerifyResponse: Decodable {
        let token: String?
        let user: UserResponse?
        let session: SessionResponse?
    }

    struct UserResponse: Decodable {
        let id: String
        let phoneNumber: String?
        let phoneNumberVerified: Bool?
    }

    struct SessionResponse: Decodable {
        let id: String
        let token: String
    }

    struct ErrorResponse: Decodable {
        let message: String?
        let code: String?
    }

    static func sendOTP(phoneNumber: String) async throws {
        let url = URL(string: "\(baseURL)/api/auth/phone-number/send-otp")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["phoneNumber": phoneNumber]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorResponse.message ?? "Failed to send OTP")
            }
            throw AuthError.serverError("Request failed with status \(httpResponse.statusCode)")
        }
    }

    static func verifyOTP(phoneNumber: String, code: String) async throws -> (token: String, userId: String) {
        let url = URL(string: "\(baseURL)/api/auth/phone-number/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "phoneNumber": phoneNumber,
            "code": code,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorResponse.message ?? "Verification failed")
            }
            throw AuthError.serverError("Request failed with status \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.invalidResponse
        }

        let token = (json["session"] as? [String: Any])?["token"] as? String
            ?? (json["token"] as? String)
            ?? ""
        let userId = (json["user"] as? [String: Any])?["id"] as? String ?? ""

        return (token: token, userId: userId)
    }

    static func validateSession(token: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/me") else { return false }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
}

enum AuthError: LocalizedError {
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let message):
            return message
        }
    }
}
