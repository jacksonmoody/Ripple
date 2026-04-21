import SwiftUI

enum AppScreen: Equatable {
    case landing
    case phoneAuth
    case contactsPermission
    case contactList
    case network
}

@Observable
class AppState {
    var currentScreen: AppScreen = .landing
    var isAuthenticated = false
    var ralliedCount = 0
    var ralliedContactIDs: Set<String> = []

    var userPhoneNumber: String = "" {
        didSet { UserDefaults.standard.set(userPhoneNumber, forKey: "userPhoneNumber") }
    }
    var sessionToken: String = "" {
        didSet { UserDefaults.standard.set(sessionToken, forKey: "sessionToken") }
    }
    var userId: String = "" {
        didSet { UserDefaults.standard.set(userId, forKey: "userId") }
    }

    init() {
        self.userPhoneNumber = UserDefaults.standard.string(forKey: "userPhoneNumber") ?? ""
        self.sessionToken = UserDefaults.standard.string(forKey: "sessionToken") ?? ""
        self.userId = UserDefaults.standard.string(forKey: "userId") ?? ""
    }

    var hasSavedSession: Bool {
        !sessionToken.isEmpty && !userId.isEmpty
    }

    func clearSession() {
        sessionToken = ""
        userId = ""
        userPhoneNumber = ""
        isAuthenticated = false
        currentScreen = .landing
    }
}
