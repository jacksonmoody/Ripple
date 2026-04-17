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
            CNContactPostalAddressesKey as CNKeyDescriptor,
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
                let hasPhoto = cnContact.thumbnailImageData != nil

                // Tier 1: Check if contact has a postal address on the device
                var addressSource: AddressSource = .none
                var resolvedState: String? = nil
                var resolvedAddress: String? = nil

                if let postal = cnContact.postalAddresses.first?.value,
                   !postal.state.isEmpty {
                    addressSource = .contactAddress
                    resolvedState = postal.state
                    let parts = [postal.street, postal.city, postal.state, postal.postalCode]
                        .filter { !$0.isEmpty }
                    resolvedAddress = parts.joined(separator: ", ")
                }

                // Tier 3 fallback: area code (applied now, may be upgraded by SmartMatch later)
                if addressSource == .none {
                    if let state = AreaCodeMapper.state(forPhoneNumber: phone) {
                        addressSource = .areaCode
                        resolvedState = state
                    }
                }

                let election = resolvedState.flatMap { ElectionService.upcomingElection(forState: $0) }

                let rippleContact = RippleContact(
                    id: cnContact.identifier,
                    contact: cnContact,
                    upcomingElection: election,
                    smartMatchScore: 0,
                    hasPhoto: hasPhoto,
                    addressSource: addressSource,
                    resolvedState: resolvedState,
                    resolvedAddress: resolvedAddress
                )
                fetched.append(rippleContact)
            }

            contacts = fetched.sorted { $0.priorityScore > $1.priorityScore }

            // Tier 2: Batch SmartMatch for contacts without a device address
            await enrichWithSmartMatch()

        } catch {
            contacts = []
        }
    }

    // MARK: - SmartMatch Enrichment

    private func enrichWithSmartMatch() async {
        let needsEnrichment = contacts.enumerated().compactMap { (index, contact) -> (Int, String, String)? in
            guard contact.addressSource != .contactAddress,
                  let phone = contact.primaryPhoneNumber, !phone.isEmpty else { return nil }
            return (index, contact.id, phone)
        }

        guard !needsEnrichment.isEmpty else { return }

        let phones = needsEnrichment.map { (id: $0.1, phone: $0.2) }

        do {
            let results = try await SmartMatchService.resolveAddresses(for: phones)

            for (index, contactID, _) in needsEnrichment {
                guard let result = results[contactID] else { continue }

                contacts[index].addressSource = .smartMatch
                contacts[index].resolvedState = result.state
                let parts = [result.address, result.city, result.state, result.zip]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                contacts[index].resolvedAddress = parts.joined(separator: ", ")
            }

            contacts.sort { $0.priorityScore > $1.priorityScore }
        } catch {
            print("SmartMatch enrichment failed: \(error.localizedDescription)")
            // Contacts keep their area code fallback — no crash
        }
    }
}
