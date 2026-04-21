import SwiftUI
import UIKit

// MARK: - Tab

enum NetworkTab: String, CaseIterable {
    case network
    case impact
    case leaderboard
    case profile

    var title: String {
        switch self {
        case .network: "Your Ripple"
        case .impact: "Your Impact"
        case .leaderboard: "Leaderboard"
        case .profile: "Profile"
        }
    }
}

// MARK: - Network Contact

struct NetworkContact: Identifiable {
    let id: String
    let rippleContact: RippleContact
    let avatarColor: Color

    var profileName: String?
    var profileAvatarURL: URL?

    var fullName: String { profileName ?? rippleContact.fullName }

    var initials: String {
        if let name = profileName {
            let parts = name.split(separator: " ")
            let first = parts.first.flatMap { $0.first }.map(String.init) ?? ""
            let last = parts.count > 1 ? parts.last.flatMap { $0.first }.map(String.init) ?? "" : ""
            let result = first + last
            return result.isEmpty ? rippleContact.initials : result.uppercased()
        }
        return rippleContact.initials
    }

    var upcomingElection: Election? { rippleContact.upcomingElection }
    var primaryPhoneNumber: String? { rippleContact.primaryPhoneNumber }
    var smartMatchScore: Int { rippleContact.smartMatchScore }
    var thumbnailImage: UIImage? { rippleContact.thumbnailImage }

    var hasRippleProfile: Bool { profileName != nil || profileAvatarURL != nil }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Identifiable {
    let id: String
    let name: String
    let initials: String
    let rallyCount: Int
    let color: Color
    let textColor: Color
    let isUser: Bool
    var rank: Int
    var avatarURL: URL?
}

// MARK: - Colors

enum NetworkColors {
    static let darkBlue = Color(red: 0.118, green: 0.204, blue: 0.549)

    static let gradientStart = Color(red: 0.094, green: 0.173, blue: 0.486)
    static let gradientMid = Color(red: 0.149, green: 0.251, blue: 0.651)
    static let gradientEnd = Color(red: 0.267, green: 0.455, blue: 0.855)

    static let gradient = LinearGradient(
        colors: [gradientStart, gradientMid, gradientEnd],
        startPoint: UnitPoint(x: 0.1, y: 0),
        endPoint: UnitPoint(x: 0.9, y: 1)
    )

    static let tabBarBackground = Color(red: 0.086, green: 0.157, blue: 0.431).opacity(0.88)

    static let glassBackground = Color.white.opacity(0.09)
    static let glassBorder = Color.white.opacity(0.12)

    static let avatarPalette: [Color] = [
        Color(red: 0.47, green: 0.67, blue: 1.0),   // blue
        Color(red: 0.66, green: 0.55, blue: 1.0),   // purple
        Color(red: 0.31, green: 0.78, blue: 1.0),   // cyan
        Color(red: 0.31, green: 0.89, blue: 0.67),   // green
        Color(red: 1.0, green: 0.77, blue: 0.35),    // gold
        Color(red: 1.0, green: 0.55, blue: 0.55),    // coral
    ]

    static let avatarTextColors: [Color] = [
        .white, .white, .white,
        Color(red: 0.06, green: 0.27, blue: 0.18),
        Color(red: 0.31, green: 0.20, blue: 0.0),
        .white,
    ]

    static func avatarColor(forIndex index: Int) -> Color {
        avatarPalette[index % avatarPalette.count]
    }

    static func avatarTextColor(forIndex index: Int) -> Color {
        avatarTextColors[index % avatarTextColors.count]
    }
}
