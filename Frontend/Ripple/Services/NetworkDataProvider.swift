import SwiftUI

@Observable
class NetworkDataProvider {
    let appState: AppState
    let contactsManager: ContactsManager

    // Backend data
    var backendNudges: [NetworkService.NudgeEntry] = []
    var leaderboard: [NetworkService.LeaderboardEntryResponse] = []
    var currentUserRank: Int?
    var currentUserNudgeCount: Int = 0
    var stats: NetworkService.StatsResponse?
    var isLoading = false

    init(appState: AppState, contactsManager: ContactsManager) {
        self.appState = appState
        self.contactsManager = contactsManager
    }

    // MARK: - Fetch from backend

    func fetchAll() async {
        isLoading = true
        defer { isLoading = false }

        let token = appState.sessionToken
        guard !token.isEmpty else { return }

        async let nudgesTask = try? NetworkService.getNudges(token: token)
        async let leaderboardTask = try? NetworkService.getLeaderboard(token: token)
        async let statsTask = try? NetworkService.getStats(token: token)

        let (nudgesResult, leaderboardResult, statsResult) = await (nudgesTask, leaderboardTask, statsTask)

        if let nudges = nudgesResult {
            backendNudges = nudges.nudges
            // Sync local count with backend
            appState.nudgedCount = nudges.total
        }

        if let lb = leaderboardResult {
            leaderboard = lb.leaderboard
            currentUserRank = lb.currentUser.rank
            currentUserNudgeCount = lb.currentUser.nudgeCount
        }

        if let s = statsResult {
            stats = s
        }
    }

    // MARK: - Local nudged contacts (matched from device contacts)

    var nudgedContacts: [NetworkContact] {
        let nudgedIDs = appState.nudgedContactIDs
        let matched = contactsManager.contacts
            .filter { nudgedIDs.contains($0.id) }
            .enumerated()
            .map { index, contact in
                NetworkContact(
                    id: contact.id,
                    rippleContact: contact,
                    avatarColor: NetworkColors.avatarColor(forIndex: index)
                )
            }
        return matched
    }

    var nudgedCount: Int {
        // Prefer backend count if available, fall back to local
        if currentUserNudgeCount > 0 {
            return currentUserNudgeCount
        }
        return appState.nudgedCount
    }

    // MARK: - Election stats

    var daysToElection: Int? {
        let now = Date()
        let elections = contactsManager.contacts
            .compactMap(\.upcomingElection)
            .map(\.date)
            .filter { $0 > now }

        guard let nearest = elections.min() else { return nil }
        return Calendar.current.dateComponents([.day], from: now, to: nearest).day
    }

    var contactsWithElections: Int {
        contactsManager.contacts.filter { $0.upcomingElection != nil }.count
    }

    var totalContacts: Int {
        contactsManager.contacts.count
    }

    // MARK: - Leaderboard entries (for the view)

    var leaderboardEntries: [LeaderboardEntry] {
        leaderboard.enumerated().map { index, entry in
            LeaderboardEntry(
                id: entry.userId,
                name: entry.isCurrentUser ? "You" : entry.name,
                initials: initials(for: entry.isCurrentUser ? "You" : entry.name),
                nudgeCount: entry.nudgeCount,
                color: entry.isCurrentUser ? .white : NetworkColors.avatarColor(forIndex: index),
                textColor: entry.isCurrentUser ? NetworkColors.darkBlue : .white,
                isUser: entry.isCurrentUser,
                rank: entry.rank
            )
        }
    }

    // MARK: - Recent activity (from backend)

    var recentNudges: [NetworkService.RecentNudge] {
        stats?.recentNudges ?? []
    }

    var totalNudgesNetwork: Int {
        stats?.totalNudgesNetwork ?? 0
    }

    var totalUsersNudging: Int {
        stats?.totalUsersNudging ?? 0
    }

    // MARK: - Goal tracking

    var goalTarget: Int { 50 }

    var progressFraction: Double {
        guard goalTarget > 0 else { return 0 }
        return min(Double(nudgedCount) / Double(goalTarget), 1.0)
    }

    // MARK: - Helpers

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first.flatMap { $0.first }.map(String.init) ?? ""
        let last = parts.count > 1 ? parts.last.flatMap { $0.first }.map(String.init) ?? "" : ""
        let result = first + last
        return result.isEmpty ? "?" : result.uppercased()
    }
}
