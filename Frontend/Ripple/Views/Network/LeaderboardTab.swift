import SwiftUI
import UIKit

struct LeaderboardTab: View {
    let provider: NetworkDataProvider
    var onRallyMore: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. Leaderboard
                if provider.leaderboardEntries.count >= 3 {
                    podium
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    if provider.leaderboardEntries.count > 3 {
                        rankedList
                            .padding(.horizontal, 18)
                    }
                } else {
                    fallbackLeaderboard
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                }

                // 2. Rank callout
                if let rank = provider.currentUserRank {
                    rankCallout(rank: rank)
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                }

                // 3. Score breakdown
                scoreBreakdownSection
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                // 4. Progress bar
                progressBar
                    .padding(.horizontal, 22)
                    .padding(.top, 16)

                // 5. Recent activity
                if !provider.recentRallies.isEmpty {
                    recentActivity
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                }

                // 6. CTA
                ctaCard
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Podium

    private var podium: some View {
        let entries = provider.leaderboardEntries
        return HStack(alignment: .bottom, spacing: 6) {
            if entries.count >= 3 {
                podiumCard(entry: entries[1], barHeight: 54, scale: 0.93)
                podiumCard(entry: entries[0], barHeight: 78, scale: 1.1)
                podiumCard(entry: entries[2], barHeight: 40, scale: 0.88)
            }
        }
    }

    private func podiumCard(entry: LeaderboardEntry, barHeight: CGFloat, scale: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text("#\(entry.rank)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.42))
                .padding(.bottom, 4)

            if let url = entry.avatarURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Text(entry.initials)
                        .font(.system(size: CGFloat(11) * scale, weight: .heavy))
                        .foregroundStyle(entry.textColor)
                }
                .frame(width: 46 * scale, height: 46 * scale)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(
                        entry.rank == 1 ? .white.opacity(0.5) : .white.opacity(0.2),
                        lineWidth: entry.rank == 1 ? 2.5 : 2
                    )
                )
                .shadow(color: entry.rank == 1 ? .white.opacity(0.18) : .clear, radius: entry.rank == 1 ? 10 : 0)
            } else {
                Text(entry.initials)
                    .font(.system(size: CGFloat(11) * scale, weight: .heavy))
                    .foregroundStyle(entry.textColor)
                    .frame(width: 46 * scale, height: 46 * scale)
                    .background(entry.color, in: Circle())
                    .overlay(
                        Circle().stroke(
                            entry.rank == 1 ? .white.opacity(0.5) : .white.opacity(0.2),
                            lineWidth: entry.rank == 1 ? 2.5 : 2
                        )
                    )
                    .shadow(color: entry.rank == 1 ? .white.opacity(0.18) : .clear, radius: entry.rank == 1 ? 10 : 0)
            }

            Text(entry.name.split(separator: " ").first.map(String.init) ?? entry.name)
                .font(.system(size: 11 + (scale - 1) * 3, weight: entry.rank == 1 ? .bold : .semibold))
                .foregroundStyle(.white)
                .padding(.top, 5)

            Text("\(entry.score)")
                .font(.system(size: 19 + (scale - 1) * 5, weight: .bold))
                .foregroundStyle(.white)

            Text("pts")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))

            RoundedRectangle(cornerRadius: 7)
                .fill(entry.rank == 1 ? .white.opacity(0.16) : .white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .frame(height: barHeight)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ranked List (positions 4+)

    private var rankedList: some View {
        let entries = Array(provider.leaderboardEntries.dropFirst(3))
        let maxScore = provider.leaderboardEntries.first?.score ?? 1

        return VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(spacing: 11) {
                    Text("#\(entry.rank)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.38))
                        .frame(width: 24)

                    if let url = entry.avatarURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Text(entry.initials)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(entry.textColor)
                        }
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                    } else {
                        Text(entry.initials)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(entry.textColor)
                            .frame(width: 34, height: 34)
                            .background(entry.color, in: Circle())
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)

                        GeometryReader { geo in
                            Capsule()
                                .fill(.white.opacity(0.12))
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(.white.opacity(0.5))
                                        .frame(width: geo.size.width * CGFloat(entry.score) / CGFloat(max(maxScore, 1)))
                                }
                        }
                        .frame(height: 3)
                    }

                    Text("\(entry.score)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 18, alignment: .trailing)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 15)

                if index < entries.count - 1 {
                    Divider().background(.white.opacity(0.08))
                }
            }
        }
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 14, bottomTrailingRadius: 14, topTrailingRadius: 0)
                .fill(.white.opacity(0.08))
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 14, bottomTrailingRadius: 14, topTrailingRadius: 0)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Fallback Leaderboard (< 3 users)

    private var fallbackLeaderboard: some View {
        VStack(spacing: 12) {
            ForEach(provider.leaderboardEntries) { entry in
                HStack(spacing: 11) {
                    Text("#\(entry.rank)")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.42))
                        .frame(width: 28)

                    if let url = entry.avatarURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Text(entry.initials)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(entry.textColor)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Text(entry.initials)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(entry.textColor)
                            .frame(width: 40, height: 40)
                            .background(entry.color, in: Circle())
                    }

                    Text(entry.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(entry.score) pts")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 13)
                        .fill(.white.opacity(entry.isUser ? 0.14 : 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(.white.opacity(entry.isUser ? 0.25 : 0.1), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Rank Callout

    private func rankCallout(rank: Int) -> some View {
        HStack(spacing: 13) {
            Text("#\(rank)")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.2), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 1) {
                Text("You're #\(rank) in your network!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                if rank > 1 {
                    let target = provider.leaderboardEntries.first(where: { $0.rank == rank - 1 })
                    let diff = (target?.score ?? 0) - provider.currentUserScore
                    if diff > 0 {
                        Text("\(diff) more points to reach #\(rank - 1)")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Score Breakdown

    private var scoreBreakdownSection: some View {
        let bd = provider.scoreBreakdown
        let textsSent = provider.stats?.textsSent ?? 0
        let directSignups = provider.stats?.directSignups ?? 0
        let secondDegree = provider.stats?.secondDegreeSignups ?? 0

        return VStack(alignment: .leading, spacing: 8) {
            Text("YOUR SCORE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.38))
                .tracking(0.8)

            VStack(spacing: 6) {
                scoreRow(
                    icon: "message.fill",
                    label: "Texts sent",
                    count: textsSent,
                    multiplier: 10,
                    points: bd?.textsPoints ?? 0
                )
                scoreRow(
                    icon: "person.badge.plus",
                    label: "Signups from your rallies",
                    count: directSignups,
                    multiplier: 50,
                    points: bd?.signupsPoints ?? 0
                )
                scoreRow(
                    icon: "person.2.fill",
                    label: "Second-degree referrals",
                    count: secondDegree,
                    multiplier: 5,
                    points: bd?.secondDegreePoints ?? 0
                )

                Divider().background(.white.opacity(0.15))

                HStack {
                    Text("Total Score")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(provider.currentUserScore) pts")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 15)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(NetworkColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(NetworkColors.glassBorder, lineWidth: 1)
                    )
            )
        }
    }

    private func scoreRow(icon: String, label: String, count: Int, multiplier: Int, points: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 18)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Text("\(count) x \(multiplier)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))

            Text("= \(points)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 44, alignment: .trailing)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.13))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.55), .white.opacity(0.88)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * provider.progressFraction)
                        .animation(.easeOut(duration: 1.0), value: provider.progressFraction)
                }
            }
            .frame(height: 7)

            HStack {
                Text("0")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.32))

                Spacer()

                Text("Goal: \(provider.goalTarget) pts \u{00B7} \(Int(provider.progressFraction * 100))% there")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.32))

                Spacer()

                Text("\(provider.goalTarget)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.32))
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT ACTIVITY")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.38))
                .tracking(0.8)

            ForEach(provider.recentRallies, id: \.id) { rally in
                HStack(spacing: 10) {
                    Circle()
                        .fill(.white.opacity(0.6))
                        .frame(width: 8, height: 8)

                    Text("You")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    + Text(" rallied \(rally.contactName)")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()

                    Text(relativeTime(from: rally.createdAt))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
    }

    private func relativeTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else {
            let f2 = ISO8601DateFormatter()
            guard let date2 = f2.date(from: isoString) else { return "" }
            return relativeTimeString(from: date2)
        }
        return relativeTimeString(from: date)
    }

    private func relativeTimeString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    // MARK: - CTA

    private var ctaCard: some View {
        Button(action: onRallyMore) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Rally more contacts")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NetworkColors.darkBlue)
                    Text("Every rally earns you 10 points")
                        .font(.system(size: 12))
                        .foregroundStyle(NetworkColors.darkBlue.opacity(0.55))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(NetworkColors.darkBlue)
            }
            .padding(.vertical, 14).padding(.horizontal, 17)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 13))
        }
    }
}
