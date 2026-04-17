import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @State private var contactsManager = ContactsManager()
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
                    withAnimation { appState.currentScreen = .contactsPermission }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .contactsPermission:
                ContactsPermissionView(contactsManager: contactsManager) {
                    withAnimation { appState.currentScreen = .contactList }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .contactList:
                ContactListView(appState: appState, contactsManager: contactsManager) {
                    withAnimation { appState.currentScreen = .success }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .success:
                SuccessView(nudgedCount: appState.nudgedCount) {
                    withAnimation { appState.currentScreen = .contactList }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.currentScreen)
        .task {
            if appState.hasSavedSession {
                let valid = await AuthService.validateSession(token: appState.sessionToken)
                if valid {
                    appState.isAuthenticated = true
                    appState.currentScreen = .contactList
                } else {
                    appState.clearSession()
                }
            }
            isCheckingSession = false
        }
    }
}

#Preview {
    ContentView()
}
