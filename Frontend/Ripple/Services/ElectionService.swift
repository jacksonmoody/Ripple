import Foundation

enum ElectionService {

    // TODO: Replace with real election API (Google Civic Information, Democracy Works, etc.)
    static func upcomingElection(forState state: String) -> Election? {
        guard let entry = mockElections[state] else { return nil }
        return Election(name: entry.name, date: entry.date, state: state)
    }

    private static let cal = Calendar.current

    private static let mockElections: [String: (name: String, date: Date)] = {
        var map: [String: (String, Date)] = [:]
        let cal = Calendar.current

        func d(_ month: Int, _ day: Int, _ year: Int = 2026) -> Date {
            cal.date(from: DateComponents(year: year, month: month, day: day))!
        }

        // 2026 primaries and elections (representative sample)
        map["GA"] = ("Georgia Primary", d(5, 19))
        map["TX"] = ("Texas Primary Runoff", d(5, 26))
        map["PA"] = ("Pennsylvania Primary", d(5, 19))
        map["NC"] = ("North Carolina Primary", d(5, 5))
        map["OH"] = ("Ohio Primary", d(5, 5))
        map["IN"] = ("Indiana Primary", d(5, 5))
        map["NE"] = ("Nebraska Primary", d(5, 12))
        map["WV"] = ("West Virginia Primary", d(5, 12))
        map["OR"] = ("Oregon Primary", d(5, 19))
        map["KY"] = ("Kentucky Primary", d(5, 19))
        map["AL"] = ("Alabama Primary Runoff", d(6, 2))
        map["CA"] = ("California Primary", d(6, 9))
        map["IA"] = ("Iowa Primary", d(6, 2))
        map["NJ"] = ("New Jersey Primary", d(6, 9))
        map["VA"] = ("Virginia Primary", d(6, 16))
        map["SC"] = ("South Carolina Primary", d(6, 9))
        map["NY"] = ("New York Primary", d(6, 23))
        map["CO"] = ("Colorado Primary", d(6, 30))
        map["FL"] = ("Florida Primary", d(8, 18))
        map["AZ"] = ("Arizona Primary", d(8, 4))
        map["MI"] = ("Michigan Primary", d(8, 4))
        map["WA"] = ("Washington Primary", d(8, 4))
        map["MN"] = ("Minnesota Primary", d(8, 11))
        map["WI"] = ("Wisconsin Primary", d(8, 11))

        // November general election for all states
        let generalStates = [
            "AK", "AR", "CT", "DC", "DE", "HI", "ID", "IL", "KS",
            "LA", "MA", "MD", "ME", "MO", "MS", "MT", "ND", "NH",
            "NM", "NV", "RI", "SD", "TN", "UT", "VT", "WY",
        ]
        for st in generalStates {
            map[st] = ("General Election", d(11, 3))
        }

        return map
    }()
}
