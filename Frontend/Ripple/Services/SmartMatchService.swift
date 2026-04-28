import Foundation

enum SmartMatchService {

    // TODO: Replace with real TargetSmart SmartMatch API integration
    // API endpoint: https://api.targetsmart.com/service/smartmatch
    // Requires x-api-key header and a TargetSmart contract.

    static func civicScore(forName name: String) -> Int {
        guard !name.isEmpty else { return 0 }
        var hash: UInt64 = 5381
        for char in name.utf8 {
            hash = hash &* 33 &+ UInt64(char)
        }
        return Int(hash % 3) // 0, 1, or 2
    }
}
