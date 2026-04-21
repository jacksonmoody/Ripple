import SwiftUI

struct ContactRowView: View {
    let contact: RippleContact
    let isSelected: Bool
    let isRallied: Bool
    var isSignedUp: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(contact.fullName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isRallied ? .secondary : .primary)

                    if isRallied {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    if isSignedUp {
                        Text("On Ripple")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.25, green: 0.4, blue: 0.85), in: Capsule())
                    }
                }

                if let election = contact.upcomingElection {
                    Label(election.name, systemImage: "calendar.badge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color(red: 0.25, green: 0.4, blue: 0.85) : .gray.opacity(0.4))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .opacity(isRallied ? 0.6 : 1.0)
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

}
