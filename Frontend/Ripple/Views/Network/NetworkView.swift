import SwiftUI

struct NetworkView: View {
    @Bindable var appState: AppState
    @Bindable var contactsManager: ContactsManager

    @State private var selectedTab: NetworkTab = .network
    @State private var selectedContact: NetworkContact?
    @State private var dataProvider: NetworkDataProvider?

    var body: some View {
        let provider = dataProvider ?? NetworkDataProvider(appState: appState, contactsManager: contactsManager)

        ZStack {
            NetworkColors.gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content(provider: provider)
            }

            // Custom tab bar
            VStack {
                Spacer()
                tabBar
            }
        }
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
            if dataProvider == nil {
                dataProvider = NetworkDataProvider(appState: appState, contactsManager: contactsManager)
            }
            await dataProvider?.fetchAll()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Button {
                    withAnimation { appState.currentScreen = .contactList }
                } label: {
                    Text("\u{2190} Home")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.46))
                }

                Text(selectedTab.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .id(selectedTab)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))

                Text(selectedTab.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button {
                withAnimation { appState.currentScreen = .contactList }
            } label: {
                Text("+ Nudge")
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
        .animation(.easeInOut(duration: 0.22), value: selectedTab)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(provider: NetworkDataProvider) -> some View {
        switch selectedTab {
        case .network:
            RippleWebTab(provider: provider, selectedContact: $selectedContact)
                .padding(.bottom, 82)
        case .impact:
            ImpactTab(provider: provider, onNudgeMore: { withAnimation { appState.currentScreen = .contactList } })
                .padding(.bottom, 82)
        case .leaderboard:
            LeaderboardTab(provider: provider, onNudgeMore: { withAnimation { appState.currentScreen = .contactList } })
                .padding(.bottom, 82)
        case .profile:
            ProfileTab(appState: appState, provider: provider)
                .padding(.bottom, 82)
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack {
            tabButton(.network, icon: "circle.grid.3x3", label: "Network")
            tabButton(.impact, icon: "chart.line.uptrend.xyaxis", label: "Impact")
            tabButton(.leaderboard, icon: "trophy", label: "Rankings")
            tabButton(.profile, icon: "person.crop.circle", label: "Profile")
        }
        .padding(.top, 8)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(NetworkColors.tabBarBackground)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: NetworkTab, icon: String, label: String) -> some View {
        let isActive = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
            }
            .foregroundStyle(isActive ? .white : .white.opacity(0.38))
            .frame(maxWidth: .infinity)
        }
    }
}
