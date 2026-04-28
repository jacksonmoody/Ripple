import Foundation

enum DeepLinkGenerator {
    static func inviteLink(forInviteCode inviteCode: String) -> String {
        var allowedCharacters = CharacterSet.urlPathAllowed
        allowedCharacters.remove(charactersIn: "/")

        let encodedInviteCode = inviteCode.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? inviteCode
        return "\(AuthService.baseURL)/invite/\(encodedInviteCode)"
    }

    static func inviteCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let pathParts = components.path
            .split(separator: "/")
            .map(String.init)

        if components.scheme == "ripple" {
            if components.host == "invite", let inviteCode = pathParts.first {
                return normalized(inviteCode)
            }

            if pathParts.first == "invite", pathParts.count > 1 {
                return normalized(pathParts[1])
            }

            return nil
        }

        guard pathParts.count == 2, pathParts[0] == "invite" else {
            return nil
        }

        return normalized(pathParts[1])
    }

    private static func normalized(_ inviteCode: String) -> String? {
        let decoded = inviteCode.removingPercentEncoding ?? inviteCode
        return decoded.isEmpty ? nil : decoded
    }
}
