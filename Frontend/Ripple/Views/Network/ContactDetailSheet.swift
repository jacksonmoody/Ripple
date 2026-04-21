import SwiftUI
import UIKit

struct ContactDetailSheet: View {
    let contact: NetworkContact
    var onViewProfile: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Contact header
            HStack(spacing: 14) {
                avatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.fullName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    if let election = contact.upcomingElection {
                        Text(election.name + " \u{00B7} " + election.formattedDate)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                Spacer()
            }

            // Contact details
            detailsSection

            // Actions
            HStack(spacing: 10) {
                Button(action: {}) {
                    Text("Send Reminder")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                }

                Button {
                    onViewProfile?()
                } label: {
                    Text("View Profile")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NetworkColors.darkBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 24)
    }

    // MARK: - Avatar

    private var avatar: some View {
        Group {
            if let image = contact.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(contact.initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(contact.avatarColor)
            }
        }
        .frame(width: 54, height: 54)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 2))
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(spacing: 10) {
            if let phone = contact.primaryPhoneNumber {
                detailRow(icon: "phone.fill", label: "Phone", value: phone)
            }

            if let election = contact.upcomingElection {
                detailRow(icon: "calendar", label: "Election", value: election.name)
            }

            if contact.smartMatchScore > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 20)

                    Text("Civic Score")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(0..<contact.smartMatchScore, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
