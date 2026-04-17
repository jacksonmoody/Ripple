import Contacts
import UIKit

enum AddressSource: Int, Comparable {
    case none = 0
    case areaCode = 1
    case smartMatch = 2
    case contactAddress = 3

    static func < (lhs: AddressSource, rhs: AddressSource) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct RippleContact: Identifiable {
    let id: String
    let contact: CNContact
    let upcomingElection: Election?
    let smartMatchScore: Int
    let hasPhoto: Bool
    var addressSource: AddressSource
    var resolvedState: String?
    var resolvedAddress: String?

    var priorityScore: Int {
        var score = 0
        if upcomingElection != nil { score += 3 }
        score += addressSource.rawValue
        if hasPhoto { score += 1 }
        return score
    }

    var fullName: String {
        [contact.givenName, contact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var initials: String {
        let first = contact.givenName.first.map(String.init) ?? ""
        let last = contact.familyName.first.map(String.init) ?? ""
        let result = first + last
        return result.isEmpty ? "?" : result
    }

    var primaryPhoneNumber: String? {
        contact.phoneNumbers.first?.value.stringValue
    }

    var thumbnailImage: UIImage? {
        guard let data = contact.thumbnailImageData else { return nil }
        return UIImage(data: data)
    }
}
