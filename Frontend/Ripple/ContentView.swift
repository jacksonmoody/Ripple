import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @State private var contactsManager = ContactsManager()

    var body: some View {
        Group {
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
        .animation(.easeInOut(duration: 0.35), value: appState.currentScreen)
    }
}

#Preview {
    ContentView()
}
