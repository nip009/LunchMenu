import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Velg lokasjon" }
    
    @Parameter(title: "Lunsj hos", default: .fb38)
    var selectedLocation: LocationOption
}
