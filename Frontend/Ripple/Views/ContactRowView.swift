import SwiftUI

struct ContactRowView: View {
    let contact: RippleContact
    let isSelected: Bool
    let isNudged: Bool

    var body: some View {
        HStack(spacing: 14) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(contact.fullName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isNudged ? .secondary : .primary)

                    if isNudged {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 8) {
                    if let election = contact.upcomingElection {
                        Label(election.name, systemImage: "calendar.badge.exclamationmark")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                    }

                    if contact.smartMatchScore > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<contact.smartMatchScore, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                            }
                        }
                        .foregroundStyle(.yellow)
                    }
                }
            }

            Spacer()

            priorityBadge

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color(red: 0.25, green: 0.4, blue: 0.85) : .gray.opacity(0.4))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .opacity(isNudged ? 0.6 : 1.0)
    }

    private var avatar: some View {
        Group {
            if let image = contact.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(contact.initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.25, green: 0.4, blue: 0.85).opacity(0.7))
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private var priorityBadge: some View {
        Group {
            if contact.priorityScore >= 5 {
                Text("HIGH")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.red, in: Capsule())
            } else if contact.priorityScore >= 3 {
                Text("MED")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.orange, in: Capsule())
            }
        }
    }
}
