import SwiftUI

enum Location: String, CaseIterable {
    case fb38 = "FB38"
    case n58 = "N58"

    var displayName: String {
        switch self {
        case .fb38: return "FB38"
        case .n58: return "N58"
        }
    }
}
