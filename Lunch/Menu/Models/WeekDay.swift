import SwiftUI

enum WeekDay: String, CaseIterable {
    case monday = "MANDAG"
    case tuesday = "TIRSDAG"
    case wednesday = "ONSDAG"
    case thursday = "TORSDAG"
    case friday = "FREDAG"
    
    static func currentDay() -> WeekDay? {
        let dayName = DateFormatter.norwegianWeekday.string(from: Date()).lowercased()
        
        switch dayName {
        case "mandag": return .monday
        case "tirsdag": return .tuesday
        case "onsdag": return .wednesday
        case "torsdag": return .thursday
        case "fredag": return .friday
        default: return nil
        }
    }
}
