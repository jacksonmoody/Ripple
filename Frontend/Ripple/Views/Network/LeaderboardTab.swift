import SwiftUI
import UIKit

struct LeaderboardTab: View {
    let provider: NetworkDataProvider
    var onRallyMore: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if provider.leaderboardEntries.count >= 3 {
                    // Podium for top 3
                    podium
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    // Remaining ranked rows
                    if provider.leaderboardEntries.count > 3 {
                        rankedList
                            .padding(.horizontal, 18)
                    }

                    // Your rank callout
                    if let rank = provider.currentUserRank {
                        rankCallout(rank: rank)
                            .padding(.horizontal, 18)
                            .padding(.top, 12)
                    }
                } else {
                    // Not enough users for a full leaderboard
                    userStatsHero
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    ralliedBreakdown
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                }

                // CTA
                ctaCard
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
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

            Text("\(entry.rallyCount)")
                .font(.system(size: 19 + (scale - 1) * 5, weight: .bold))
                .foregroundStyle(.white)

            // Bar
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
        let maxRallies = provider.leaderboardEntries.first?.rallyCount ?? 1

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
                                        .frame(width: geo.size.width * CGFloat(entry.rallyCount) / CGFloat(max(maxRallies, 1)))
                                }
                        }
                        .frame(height: 3)
                    }

                    Text("\(entry.rallyCount)")
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
                    let diff = (target?.rallyCount ?? 0) - provider.ralliedCount
                    if diff > 0 {
                        Text("Rally \(diff) more to reach #\(rank - 1)")
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

    // MARK: - Fallback: User Stats Hero (when not enough leaderboard data)

    private var userStatsHero: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(.white.opacity(0.08)).frame(width: 90, height: 90)
                    Circle().fill(.white.opacity(0.2)).frame(width: 72, height: 72)
                        .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 1.5))
                    Text("ME")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(NetworkColors.darkBlue)
                        .frame(width: 60, height: 60)
                        .background(.white, in: Circle())
                }
                Text("Your Stats")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 10) {
                statBox(value: "\(provider.ralliedCount)", label: "Rallied")
                statBox(value: "\(provider.contactsWithElections)", label: "w/ Elections")
                statBox(value: "\(provider.totalContacts)", label: "Total Contacts")
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.15), lineWidth: 1))
        )
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 1))
        )
    }

    // MARK: - Rallied Breakdown (fallback)

    private var ralliedBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PEOPLE YOU'VE RALLIED")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.38))
                .tracking(0.8)

            if provider.ralliedContacts.isEmpty {
                Text("No contacts rallied yet")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(provider.ralliedContacts.enumerated()), id: \.element.id) { index, contact in
                    HStack(spacing: 11) {
                        Text("#\(index + 1)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.38))
                            .frame(width: 24)

                        if let avatarURL = contact.profileAvatarURL {
                            AsyncImage(url: avatarURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Text(contact.initials)
                                    .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(contact.avatarColor, in: Circle())
                            }
                            .frame(width: 34, height: 34).clipShape(Circle())
                        } else if let image = contact.thumbnailImage {
                            Image(uiImage: image)
                                .resizable().scaledToFill()
                                .frame(width: 34, height: 34).clipShape(Circle())
                        } else {
                            Text(contact.initials)
                                .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(contact.avatarColor, in: Circle())
                        }

                        Text(contact.fullName)
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 8)

                    if index < provider.ralliedContacts.count - 1 {
                        Divider().background(.white.opacity(0.08))
                    }
                }
            }
        }
        .padding(.vertical, 14).padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1), lineWidth: 1))
        )
    } 

    // MARK: - CTA

    private var ctaCard: some View {
        Button(action: onRallyMore) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Rally more contacts")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NetworkColors.darkBlue)
                    Text("Every rally counts toward your impact")
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
