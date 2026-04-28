import MessageUI
import SwiftUI

struct ContactListView: View {
    @Bindable var appState: AppState
    @Bindable var contactsManager: ContactsManager
    @Bindable var provider: NetworkDataProvider
    var onRallySent: () -> Void

    @State private var pendingContact: RippleContact?
    @State private var showMessageComposer = false
    @State private var searchText = ""
    @State private var inviteLink = ""
    @State private var preparingContactID: String?
    @State private var inviteError: String?

    private var isOnboarding: Bool { !appState.hasCompletedOnboarding }
    private var ralliedSoFar: Int { provider.ralliedContactIDs.count }
    private var requiredRallies: Int { AppState.requiredOnboardingRallies }
    private var onboardingComplete: Bool { ralliedSoFar >= requiredRallies }

    private var filteredContacts: [RippleContact] {
        if searchText.isEmpty {
            return contactsManager.contacts
        }
        return contactsManager.contacts.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var rallyMessageBody: String {
        let election = pendingContact?.upcomingElection
        let electionPhrase = election.map { "the \($0.name)" } ?? "the upcoming election"
        return "Hey, I've been thinking about \(electionPhrase) and wanted to make sure you're planning to vote in it. Join me on Ripple to help spread the word! \(inviteLink)"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                searchBar

                if contactsManager.isLoading {
                    Spacer()
                    ProgressView("Loading contacts...")
                    Spacer()
                } else if filteredContacts.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    contactList
                }
            }
            .background(Color(red: 0.96, green: 0.97, blue: 1.0))

            if isOnboarding && onboardingComplete {
                continueButton
            }
        }
        .task {
            if contactsManager.contacts.isEmpty {
                await contactsManager.fetchContacts()
            }
        }
        .sheet(isPresented: $showMessageComposer) {
            MessageComposerView(
                isPresented: $showMessageComposer,
                recipients: [pendingContact?.primaryPhoneNumber].compactMap { $0 },
                messageBody: rallyMessageBody,
                onResult: handleMessageResult
            )
            .ignoresSafeArea()
        }
        .alert("Invite link unavailable", isPresented: Binding(
            get: { inviteError != nil },
            set: { if !$0 { inviteError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(inviteError ?? "Please try again.")
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            if isOnboarding {
                VStack(spacing: 6) {
                    Text("Rally \(requiredRallies) contacts to get started!")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 8) {
                        ProgressView(value: Double(ralliedSoFar), total: Double(requiredRallies))
                            .tint(Color(red: 0.25, green: 0.4, blue: 0.85))

                        Text("\(ralliedSoFar)/\(requiredRallies)")
                            .font(.caption.bold())
                            .foregroundStyle(Color(red: 0.25, green: 0.4, blue: 0.85))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            } else {
                HStack {
                    Button {
                        appState.navigatingBack = true
                        appState.currentScreen = .network
                        DispatchQueue.main.async { appState.navigatingBack = false }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundStyle(Color(red: 0.25, green: 0.4, blue: 0.85))
                    }

                    Spacer()

                    if (provider.userProfile?.rallyCount ?? 0) > 0 {
                        VStack(spacing: 2) {
                            Text("\(provider.userProfile?.rallyCount ?? 0)")
                                .font(.title3.bold())
                                .foregroundStyle(Color(red: 0.25, green: 0.4, blue: 0.85))
                            Text("rallied")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 4)

                Text("Your Contacts")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search contacts", text: $searchText)
                .font(.body)
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var contactList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredContacts) { contact in
                    ContactRowView(
                        contact: contact,
                        isPreparing: preparingContactID == contact.id,
                        isRallied: provider.ralliedContactIDs.contains(contact.id),
                        isSignedUp: provider.signedUpContactIDs.contains(contact.id)
                    )
                    .onTapGesture {
                        guard !provider.ralliedContactIDs.contains(contact.id) else { return }
                        guard preparingContactID == nil else { return }
                        if MFMessageComposeViewController.canSendText() {
                            Task { await rallyContact(contact) }
                        }
                    }

                    if contact.id != filteredContacts.last?.id {
                        Divider().padding(.leading, 74)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No contacts found")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var continueButton: some View {
        Button {
            appState.hasCompletedOnboarding = true
            withAnimation { appState.currentScreen = .network }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                Text("Continue to Ripple")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(red: 0.25, green: 0.4, blue: 0.85), in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func handleMessageResult(_ result: MessageComposeResult) {
        if result == .sent, let contact = pendingContact {
            provider.recordRallies([contact])
            if !isOnboarding {
                onRallySent()
            }
        }
        pendingContact = nil
    }

    @MainActor
    private func rallyContact(_ contact: RippleContact) async {
        preparingContactID = contact.id
        defer { preparingContactID = nil }

        do {
            let invite = try await NetworkService.getInvite(token: appState.sessionToken)
            inviteLink = invite.inviteUrl
            pendingContact = contact
            showMessageComposer = true
        } catch {
            inviteError = "We couldn't create your invite link. Please try again."
        }
    }
}
