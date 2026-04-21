import SwiftUI
import Combine

struct ImpactTab: View {
    let provider: NetworkDataProvider
    var onRallyMore: () -> Void

    @State private var displayedCount = 0
    @State private var hasAnimated = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("\(displayedCount)")
                        .font(.system(size: 96, weight: .heavy))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text("people rallied to vote")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.68))

                    Text("Your ripple is growing")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.38))
                        .padding(.top, 3)
                }
                .padding(.vertical, 20)

                // Progress bar
                progressBar
                    .padding(.horizontal, 22)
                    .padding(.bottom, 4)

                // Stat grid
                statGrid
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                // Recent activity
                if !provider.recentRallies.isEmpty {
                    recentActivity
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                }

                // CTA
                ctaCard
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            animateCount(to: provider.ralliedCount)
        }
    }

    // MARK: - Animated Count

    private func animateCount(to target: Int) {
        guard target > 0 else { return }
        let steps = target
        let interval = 1.0 / Double(max(steps, 1))

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                withAnimation(.easeOut(duration: 0.08)) {
                    displayedCount = i
                }
            }
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

                Text("Goal: \(provider.goalTarget) rallies \u{00B7} \(Int(provider.progressFraction * 100))% there")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.32))

                Spacer()

                Text("\(provider.goalTarget)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.32))
            }
        }
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
                statCard(value: "\(provider.ralliedCount)", label: "Directly rallied")
            statCard(value: provider.daysToElection.map { "\($0)" } ?? "--", label: "Days to election")
            statCard(value: "\(provider.contactsWithElections)", label: "Contacts w/ elections")
            statCard(value: "\(provider.totalContacts)", label: "Total contacts")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 13)
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
            // Try without fractional seconds
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
                    Text("Keep the ripple going")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NetworkColors.darkBlue)
                    Text("Rally more contacts to reach your goal")
                        .font(.system(size: 12))
                        .foregroundStyle(NetworkColors.darkBlue.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(NetworkColors.darkBlue)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
            .background(.white.opacity(0.93), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
