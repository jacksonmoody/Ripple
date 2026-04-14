import Contacts
import SwiftUI

@Observable
class ContactsManager {
    var authorizationStatus: CNAuthorizationStatus = .notDetermined
    var contacts: [RippleContact] = []
    var isLoading = false

    private let store = CNContactStore()

    init() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAccess() async {
        guard authorizationStatus == .notDetermined else { return }
        do {
            let granted = try await store.requestAccess(for: .contacts)
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            if granted {
                await fetchContacts()
            }
        } catch {
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        }
    }

    func fetchContacts() async {
        guard authorizationStatus == .authorized else { return }
        isLoading = true
        defer { isLoading = false }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .givenName

        var fetched: [RippleContact] = []

        do {
            try store.enumerateContacts(with: request) { cnContact, _ in
                guard !cnContact.phoneNumbers.isEmpty else { return }

                let phone = cnContact.phoneNumbers.first?.value.stringValue ?? ""
                let state = AreaCodeMapper.state(forPhoneNumber: phone)
                let election = state.flatMap { ElectionService.upcomingElection(forState: $0) }
                let name = [cnContact.givenName, cnContact.familyName].joined(separator: " ")
                let smartScore = SmartMatchService.civicScore(forName: name)
                let hasPhoto = cnContact.thumbnailImageData != nil

                let rippleContact = RippleContact(
                    id: cnContact.identifier,
                    contact: cnContact,
                    upcomingElection: election,
                    smartMatchScore: smartScore,
                    hasPhoto: hasPhoto
                )
                fetched.append(rippleContact)
            }

            contacts = fetched.sorted { $0.priorityScore > $1.priorityScore }
        } catch {
            contacts = []
        }
    }
}
