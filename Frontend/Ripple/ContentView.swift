import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState
    @State private var contactsManager = ContactsManager()
    @State private var dataProvider: NetworkDataProvider?
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                ProgressView()
                    .tint(Color(red: 0.25, green: 0.4, blue: 0.85))
            } else {
            switch appState.currentScreen {
            case .landing:
                LandingView {
                    withAnimation { appState.currentScreen = .phoneAuth }
                }
                .transition(.opacity)

            case .phoneAuth:
                PhoneAuthView(appState: appState) {
                    submitPendingReferral()
                    withAnimation { appState.currentScreen = .contactsPermission }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .contactsPermission:
                ContactsPermissionView(contactsManager: contactsManager) {
                    withAnimation { appState.currentScreen = .network }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .contactList:
                if let provider = dataProvider {
                    ContactListView(appState: appState, contactsManager: contactsManager, provider: provider) {
                        withAnimation { appState.currentScreen = .network }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }

            case .network:
                if let provider = dataProvider {
                    NetworkView(appState: appState, contactsManager: contactsManager, provider: provider)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            }
        }
        .onOpenURL { url in
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let ref = components.queryItems?.first(where: { $0.name == "ref" })?.value,
                  !ref.isEmpty else { return }
            appState.pendingReferrerId = ref
        }
        .animation(.easeInOut(duration: 0.35), value: appState.currentScreen)
        .preferredColorScheme(.light)
        .task {
            dataProvider = NetworkDataProvider(appState: appState, contactsManager: contactsManager)
            if appState.hasSavedSession {
                let valid = await AuthService.validateSession(token: appState.sessionToken)
                if valid {
                    appState.isAuthenticated = true
                    appState.currentScreen = .network
                } else {
                    appState.clearSession()
                }
            }
            isCheckingSession = false
        }
    }
    private func submitPendingReferral() {
        guard let ref = appState.pendingReferrerId, !ref.isEmpty else { return }
        let token = appState.sessionToken
        appState.pendingReferrerId = nil
        Task {
            try? await NetworkService.submitReferral(referrerId: ref, token: token)
        }
    }
}

#Preview {
    ContentView(appState: AppState())
}
