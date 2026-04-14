import SwiftUI

enum AppScreen: Equatable {
    case landing
    case phoneAuth
    case contactsPermission
    case contactList
    case success
}

@Observable
class AppState {
    var currentScreen: AppScreen = .landing
    var isAuthenticated = false
    var userPhoneNumber: String = ""
    var nudgedCount = 0
    var nudgedContactIDs: Set<String> = []
}
