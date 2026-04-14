import Foundation

enum DeepLinkGenerator {
    // TODO: Replace with real backend-generated invite links
    static func inviteLink(forUser phoneNumber: String) -> String {
        let sanitized = phoneNumber.filter(\.isNumber)
        let userId = String(sanitized.suffix(10))
        return "https://sway.co"
    }
}
