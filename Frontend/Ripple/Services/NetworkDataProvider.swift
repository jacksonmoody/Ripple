import SwiftUI

@Observable
class NetworkDataProvider {
    let appState: AppState
    let contactsManager: ContactsManager

    // Backend data
    var backendRallies: [NetworkService.RallyEntry] = []
    var leaderboard: [NetworkService.LeaderboardEntryResponse] = []
    var currentUserRank: Int?
    var currentUserRallyCount: Int = 0
    var stats: NetworkService.StatsResponse?
    var userProfile: NetworkService.ProfileResponse?
    var isLoading = false

    // Tracks which device contacts have been rallied (synced from backend + local)
    var ralliedContactIDs: Set<String> = []

    // Ripple user profiles keyed by normalized phone (last 10 digits)
    var contactProfilesByPhone: [String: NetworkService.ContactProfile] = [:]

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

        async let ralliesTask = try? NetworkService.getRallies(token: token)
        async let leaderboardTask = try? NetworkService.getLeaderboard(token: token)
        async let statsTask = try? NetworkService.getStats(token: token)
        async let profileTask = try? NetworkService.getProfile(token: token)

        let (ralliesResult, leaderboardResult, statsResult, profileResult) = await (ralliesTask, leaderboardTask, statsTask, profileTask)

        if let rallies = ralliesResult {
            backendRallies = rallies.rallies
            currentUserRallyCount = rallies.total
            contactProfilesByPhone = rallies.contactProfiles ?? [:]
            syncRalliedContactIDs(from: rallies.rallies)
        }

        if let lb = leaderboardResult {
            leaderboard = lb.leaderboard
            currentUserRank = lb.currentUser.rank
            if currentUserRallyCount == 0 {
                currentUserRallyCount = lb.currentUser.rallyCount
            }
        }

        if let s = statsResult {
            stats = s
        }

        if let p = profileResult {
            userProfile = p
        }
    }

    // MARK: - Record new rallies

    func recordRallies(_ contacts: [RippleContact]) {
        ralliedContactIDs.formUnion(contacts.map(\.id))
        currentUserRallyCount += contacts.count

        Task {
            let entries = contacts.map { contact in
                NetworkService.RecordRallyContact(
                    name: contact.fullName,
                    phone: contact.primaryPhoneNumber ?? ""
                )
            }
            try? await NetworkService.recordRallies(
                contacts: entries,
                token: appState.sessionToken
            )
        }
    }

    // MARK: - Sync backend rallies to local contact IDs

    private func syncRalliedContactIDs(from rallies: [NetworkService.RallyEntry]) {
        let ralliedPhones = Set(rallies.map { normalizePhone($0.contactPhone) })
        var matchedIDs = ralliedContactIDs
        for contact in contactsManager.contacts {
            guard let phone = contact.primaryPhoneNumber else { continue }
            if ralliedPhones.contains(normalizePhone(phone)) {
                matchedIDs.insert(contact.id)
            }
        }
        ralliedContactIDs = matchedIDs
    }

    private func normalizePhone(_ phone: String) -> String {
        phone.filter(\.isNumber).suffix(10).description
    }

    // MARK: - Rallied contacts (matched from device contacts)

    var ralliedContacts: [NetworkContact] {
        contactsManager.contacts
            .filter { ralliedContactIDs.contains($0.id) }
            .enumerated()
            .map { index, contact in
                var nc = NetworkContact(
                    id: contact.id,
                    rippleContact: contact,
                    avatarColor: NetworkColors.avatarColor(forIndex: index)
                )
                if let phone = contact.primaryPhoneNumber {
                    let normalized = normalizePhone(phone)
                    if let profile = contactProfilesByPhone[normalized] {
                        nc.profileName = profile.name
                        if let urlStr = profile.avatarUrl {
                            nc.profileAvatarURL = URL(string: urlStr)
                        }
                    }
                }
                return nc
            }
    }

    var ralliedCount: Int {
        currentUserRallyCount
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
            let displayName = entry.isCurrentUser ? (userDisplayName ?? "You") : entry.name
            let avatarUrlString = entry.isCurrentUser ? userProfile?.avatarUrl : entry.avatarUrl
            return LeaderboardEntry(
                id: entry.userId,
                name: displayName,
                initials: initials(for: displayName),
                rallyCount: entry.rallyCount,
                color: entry.isCurrentUser ? .white : NetworkColors.avatarColor(forIndex: index),
                textColor: entry.isCurrentUser ? NetworkColors.darkBlue : .white,
                isUser: entry.isCurrentUser,
                rank: entry.rank,
                avatarURL: avatarUrlString.flatMap { URL(string: $0) }
            )
        }
    }

    // MARK: - Recent activity (from backend)

    var recentRallies: [NetworkService.RecentRally] {
        stats?.recentRallies ?? []
    }

    var totalRalliesNetwork: Int {
        stats?.totalRalliesNetwork ?? 0
    }

    var totalUsersRallying: Int {
        stats?.totalUsersRallying ?? 0
    }

    // MARK: - Goal tracking

    var goalTarget: Int { 50 }

    var progressFraction: Double {
        guard goalTarget > 0 else { return 0 }
        return min(Double(ralliedCount) / Double(goalTarget), 1.0)
    }

    // MARK: - User profile helpers

    var userDisplayName: String? {
        guard let name = userProfile?.name, !name.isEmpty else { return nil }
        return name
    }

    var userAvatarURL: URL? {
        guard let urlString = userProfile?.avatarUrl else { return nil }
        return URL(string: urlString)
    }

    var userInitials: String {
        if let name = userDisplayName {
            return initials(for: name)
        }
        return "YOU"
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
