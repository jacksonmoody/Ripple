import MessageUI
import SwiftUI
import UIKit

struct ContactDetailSheet: View {
    let contact: NetworkContact
    let userId: String

    @State private var showMessageComposer = false

    private var messageBody: String {
        let electionPhrase = contact.upcomingElection.map { "the \($0.name)" } ?? "the upcoming election"
        let link = DeepLinkGenerator.inviteLink(forUser: userId)
        return "Hey, I've been thinking about \(electionPhrase) and wanted to remind you to vote in it. Join me on Ripple to help spread the word! \(link)"
    }

    var body: some View {
        VStack(spacing: 20) {
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

            detailsSection

            if let phone = contact.primaryPhoneNumber, MFMessageComposeViewController.canSendText() {
                Button {
                    showMessageComposer = true
                } label: {
                    Text("Send Reminder")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NetworkColors.darkBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                }
                .sheet(isPresented: $showMessageComposer) {
                    MessageComposerView(
                        isPresented: $showMessageComposer,
                        recipients: [phone],
                        messageBody: messageBody,
                        onResult: { _ in }
                    )
                    .ignoresSafeArea()
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
            if let avatarURL = contact.profileAvatarURL {
                AsyncImage(url: avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Text(contact.initials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(contact.avatarColor)
                }
            } else if let image = contact.thumbnailImage {
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
