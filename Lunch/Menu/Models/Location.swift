import AppIntents
import SwiftUI

enum Location: String, CaseIterable, AppEnum {
    case fb38 = "FB38"
    case n58 = "N58"

    var displayName: String {
        switch self {
        case .fb38: return "FB38"
        case .n58: return "N58"
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Lunsj hos"
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .fb38: "FB38",
            .n58: "N58"
        ]
    }
}
