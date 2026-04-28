import SwiftUI
import Contacts

struct ContentView: View {
    @Bindable var appState: AppState
    @State private var contactsManager = ContactsManager()
    @State private var dataProvider: NetworkDataProvider?
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                RippleLoadingView()
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
                    .transition(navigationTransition)

                case .contactsPermission:
                    ContactsPermissionView(contactsManager: contactsManager) {
                        withAnimation {
                            appState.currentScreen = appState.hasCompletedOnboarding ? .network : .contactList
                        }
                    }
                    .transition(navigationTransition)

                case .contactList:
                    if let provider = dataProvider {
                        ContactListView(appState: appState, contactsManager: contactsManager, provider: provider) {
                            withAnimation { appState.currentScreen = .network }
                        }
                        .transition(navigationTransition)
                    }

                case .network:
                    if let provider = dataProvider {
                        NetworkView(appState: appState, contactsManager: contactsManager, provider: provider)
                            .transition(navigationTransition)
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
                    if !appState.hasCompletedOnboarding {
                        if contactsManager.authorizationStatus == .authorized || contactsManager.authorizationStatus == .limited {
                            appState.currentScreen = .contactList
                        } else {
                            appState.currentScreen = .contactsPermission
                        }
                    } else {
                        appState.currentScreen = .network
                    }
                } else {
                    appState.clearSession()
                }
            }
            isCheckingSession = false
        }
    }
    private var navigationTransition: AnyTransition {
        if appState.navigatingBack {
            return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        }
        return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
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
