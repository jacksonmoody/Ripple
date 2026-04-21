import SwiftUI
import UIKit

struct RippleWebTab: View {
    let provider: NetworkDataProvider
    @Binding var selectedContact: NetworkContact?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Network graph
                RippleGraphView(
                    contacts: provider.ralliedContacts,
                    userInitials: provider.userInitials,
                    userAvatarURL: provider.userAvatarURL
                ) { contact in
                    selectedContact = contact
                }

                // Contact list
                contactList
                    .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - Contact List

    private var contactList: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("YOUR RALLIES")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.38))
                .tracking(0.8)
                .padding(.bottom, 2)

            if provider.ralliedContacts.isEmpty {
                Text("Rally contacts to see them here")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else {
                ForEach(provider.ralliedContacts) { contact in
                    contactRow(contact)
                        .onTapGesture {
                            selectedContact = contact
                        }
                }
            }

            Spacer().frame(height: 12)
        }
    }

    private func contactRow(_ contact: NetworkContact) -> some View {
        HStack(spacing: 11) {
            if let avatarURL = contact.profileAvatarURL {
                AsyncImage(url: avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Text(contact.initials)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(contact.avatarColor, in: Circle())
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else if let image = contact.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Text(contact.initials)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(contact.avatarColor, in: Circle())
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(contact.fullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                if let election = contact.upcomingElection {
                    Text(election.name)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.48))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 13)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
