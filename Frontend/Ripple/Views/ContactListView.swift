import MessageUI
import SwiftUI

struct ContactListView: View {
    @Bindable var appState: AppState
    @Bindable var contactsManager: ContactsManager
    @Bindable var provider: NetworkDataProvider
    var onRallySent: () -> Void

    @State private var selectedIDs: Set<String> = []
    @State private var showMessageComposer = false
    @State private var searchText = ""

    private var filteredContacts: [RippleContact] {
        if searchText.isEmpty {
            return contactsManager.contacts
        }
        return contactsManager.contacts.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var selectedContacts: [RippleContact] {
        contactsManager.contacts.filter { selectedIDs.contains($0.id) }
    }

    private var rallyMessageBody: String {
        let election = selectedContacts
            .compactMap(\.upcomingElection)
            .first

        let electionPhrase = election.map { "the \($0.name)" } ?? "the upcoming election"
        let link = DeepLinkGenerator.inviteLink(forUser: appState.userId)
        return "Hey, I've been thinking about \(electionPhrase) and wanted to make sure you're planning to vote in it. Join me on Ripple to help spread the word! \(link)"
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

            if !selectedIDs.isEmpty {
                rallyButton
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
                recipients: selectedContacts.compactMap(\.primaryPhoneNumber),
                messageBody: rallyMessageBody,
                onResult: handleMessageResult
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            HStack {
                Button {
                    appState.currentScreen = .network
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

                if provider.ralliedCount > 0 {
                    VStack(spacing: 2) {
                        Text("\(provider.ralliedCount)")
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
                        isSelected: selectedIDs.contains(contact.id),
                        isRallied: provider.ralliedContactIDs.contains(contact.id),
                        isSignedUp: provider.signedUpContactIDs.contains(contact.id)
                    )
                    .onTapGesture {
                        guard !provider.ralliedContactIDs.contains(contact.id) else { return }
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if selectedIDs.contains(contact.id) {
                                selectedIDs.remove(contact.id)
                            } else {
                                selectedIDs.insert(contact.id)
                            }
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

    private var rallyButton: some View {
        Button {
            if MFMessageComposeViewController.canSendText() {
                showMessageComposer = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill")
                Text("Send Rally (\(selectedIDs.count))")
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
        .animation(.spring(response: 0.3), value: selectedIDs.isEmpty)
    }

    private func handleMessageResult(_ result: MessageComposeResult) {
        if result == .sent {
            provider.recordRallies(selectedContacts)
            selectedIDs.removeAll()
            onRallySent()
        }
    }
}
