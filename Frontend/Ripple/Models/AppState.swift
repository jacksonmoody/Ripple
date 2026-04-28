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
    var navigatingBack = false
    var isAuthenticated = false

    var userPhoneNumber: String = "" {
        didSet { UserDefaults.standard.set(userPhoneNumber, forKey: "userPhoneNumber") }
    }
    var sessionToken: String = "" {
        didSet { UserDefaults.standard.set(sessionToken, forKey: "sessionToken") }
    }
    var userId: String = "" {
        didSet { UserDefaults.standard.set(userId, forKey: "userId") }
    }
    var hasCompletedOnboarding: Bool = false {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    var pendingReferrerId: String?

    static let requiredOnboardingRallies = 3

    init() {
        self.userPhoneNumber = UserDefaults.standard.string(forKey: "userPhoneNumber") ?? ""
        self.sessionToken = UserDefaults.standard.string(forKey: "sessionToken") ?? ""
        self.userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    var hasSavedSession: Bool {
        !sessionToken.isEmpty && !userId.isEmpty
    }

    func clearSession() {
        sessionToken = ""
        userId = ""
        userPhoneNumber = ""
        hasCompletedOnboarding = false
        isAuthenticated = false
        currentScreen = .landing
    }
}
