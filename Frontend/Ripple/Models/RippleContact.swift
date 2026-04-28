import Contacts
import UIKit

struct RippleContact: Identifiable {
    let id: String
    let contact: CNContact
    let upcomingElection: Election?
    let smartMatchScore: Int
    let hasPhoto: Bool

    var closenessScore: Int {
        var score = 0
        if hasPhoto { score += 4 }
        if contact.birthday != nil { score += 3 }
        if !contact.contactRelations.isEmpty { score += 4 }
        if !contact.postalAddresses.isEmpty { score += 2 }
        if !contact.dates.isEmpty { score += 2 }
        if contact.phoneNumbers.count > 1 { score += 1 }
        if !contact.emailAddresses.isEmpty { score += 1 }
        return score
    }

    var priorityScore: Int {
        closenessScore
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
