import SwiftUI

enum WeekDay: String, CaseIterable {
    case mandag = "MANDAG"
    case tirsdag = "TIRSDAG"
    case onsdag = "ONSDAG"
    case torsdag = "TORSDAG"
    case fredag = "FREDAG"

    static func currentDay() -> WeekDay? {
        let dayName = DateFormatter.norwegianWeekday.string(from: Date()).lowercased()

        switch dayName {
        case "mandag": return .mandag
        case "tirsdag": return .tirsdag
        case "onsdag": return .onsdag
        case "torsdag": return .torsdag
        case "fredag": return .fredag
        default: return nil
        }
    }
    
    static var orderedDays: [WeekDay] {
        return [.mandag, .tirsdag, .onsdag, .torsdag, .fredag]
    }
}
