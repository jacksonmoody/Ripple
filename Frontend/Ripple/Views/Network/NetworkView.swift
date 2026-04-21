import SwiftUI

struct NetworkView: View {
    @Bindable var appState: AppState
    @Bindable var contactsManager: ContactsManager
    @Bindable var provider: NetworkDataProvider

    @State private var selectedTab: NetworkTab = .network
    @State private var selectedContact: NetworkContact?

    var body: some View {

        TabView(selection: $selectedTab) {
            Tab("Network", systemImage: "circle.grid.3x3", value: .network) {
                tabPage(tab: .network) {
                    RippleWebTab(provider: provider, selectedContact: $selectedContact)
                }
            }

            Tab("Impact", systemImage: "chart.line.uptrend.xyaxis", value: .impact) {
                tabPage(tab: .impact) {
                    ImpactTab(provider: provider, onRallyMore: { withAnimation { appState.currentScreen = .contactList } })
                }
            }

            Tab("Rankings", systemImage: "trophy", value: .leaderboard) {
                tabPage(tab: .leaderboard) {
                    LeaderboardTab(provider: provider, onRallyMore: { withAnimation { appState.currentScreen = .contactList } })
                }
            }

            Tab("Profile", systemImage: "person.crop.circle", value: .profile) {
                tabPage(tab: .profile) {
                    ProfileTab(appState: appState, provider: provider)
                }
            }
        }
        .tint(.white)
        .sheet(item: $selectedContact) { contact in
            ContactDetailSheet(contact: contact, onViewProfile: {
                selectedContact = nil
                withAnimation { selectedTab = .profile }
            })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(
                    LinearGradient(
                        colors: [Color(red: 0.125, green: 0.22, blue: 0.596), Color(red: 0.204, green: 0.345, blue: 0.784)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .task {
            if contactsManager.contacts.isEmpty {
                await contactsManager.fetchContacts()
            }
            await provider.fetchAll()
        }
    }

    // MARK: - Tab Page Wrapper

    private func tabPage<Content: View>(tab: NetworkTab, @ViewBuilder content: () -> Content) -> some View {
        ZStack {
            NetworkColors.gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header(for: tab)
                content()
            }
        }
        .toolbarBackground(NetworkColors.tabBarBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    // MARK: - Header

    private func header(for tab: NetworkTab) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text(tab.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(tab.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button {
                withAnimation { appState.currentScreen = .contactList }
            } label: {
                Text("+ Rally")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.15), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.28), lineWidth: 1))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 5)
        .padding(.bottom, 10)
    }
}
