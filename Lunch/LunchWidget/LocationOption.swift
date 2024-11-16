import AppIntents

enum LocationOption: String, AppEnum {
    case fb38 = "FB38"
    case n58 = "N58"

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
