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
        }

        if let s = statsResult {
            stats = s
        }

        if let p = profileResult {
            userProfile = p
            await prefillProfileFromContacts(profile: p)
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
                        nc.secondDegreeCount = profile.secondDegreeCount ?? 0
                    }
                }
                return nc
            }
    }

    var ralliedCount: Int {
        currentUserRallyCount
    }

    var signedUpContactIDs: Set<String> {
        var ids = Set<String>()
        for contact in contactsManager.contacts {
            guard let phone = contact.primaryPhoneNumber else { continue }
            if contactProfilesByPhone[normalizePhone(phone)] != nil {
                ids.insert(contact.id)
            }
        }
        return ids
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
                score: entry.score,
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

    // MARK: - Score

    var currentUserScore: Int {
        stats?.score ?? 0
    }

    var scoreBreakdown: NetworkService.ScoreBreakdown? {
        stats?.breakdown
    }

    // MARK: - Goal tracking

    var goalTarget: Int { 500 }

    var progressFraction: Double {
        guard goalTarget > 0 else { return 0 }
        return min(Double(currentUserScore) / Double(goalTarget), 1.0)
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

    // MARK: - Prefill from device contacts

    var ownContactName: String? {
        guard !appState.userPhoneNumber.isEmpty else { return nil }
        return contactsManager.lookupOwnContact(phoneNumber: appState.userPhoneNumber)?.fullName
    }

    var ownContactEmail: String? {
        guard !appState.userPhoneNumber.isEmpty else { return nil }
        return contactsManager.lookupOwnContact(phoneNumber: appState.userPhoneNumber)?.email
    }

    private func prefillProfileFromContacts(profile: NetworkService.ProfileResponse) async {
        let nameIsEmpty = profile.name == nil
            || profile.name!.isEmpty
            || profile.name!.hasPrefix("+")
        let emailIsEmpty = profile.email == nil || profile.email!.isEmpty

        guard nameIsEmpty || emailIsEmpty else { return }

        guard let ownContact = contactsManager.lookupOwnContact(phoneNumber: appState.userPhoneNumber) else { return }

        let nameToSave = nameIsEmpty ? ownContact.fullName : nil
        let emailToSave = emailIsEmpty ? ownContact.email : nil

        guard nameToSave != nil || emailToSave != nil else { return }

        let token = appState.sessionToken
        guard !token.isEmpty else { return }

        if let result = try? await NetworkService.updateProfile(name: nameToSave, email: emailToSave, token: token) {
            userProfile = NetworkService.ProfileResponse(
                id: profile.id,
                name: result.name ?? profile.name,
                email: result.email ?? profile.email,
                phoneNumber: profile.phoneNumber,
                createdAt: profile.createdAt,
                rallyCount: profile.rallyCount,
                uniqueContactsRallied: profile.uniqueContactsRallied,
                firstRallyAt: profile.firstRallyAt,
                avatarUrl: profile.avatarUrl
            )
        }
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
