import Foundation

enum DeepLinkGenerator {
    static func inviteLink(forUser userId: String) -> String {
        "https://sway.co/invite?ref=\(userId)"
    }
}
