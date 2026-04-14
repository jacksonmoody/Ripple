import Foundation

struct Election: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let state: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
