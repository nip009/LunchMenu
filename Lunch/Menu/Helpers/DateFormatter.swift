import Foundation

extension DateFormatter {
    static let norwegianWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "no_NO")
        return formatter
    }()
}
