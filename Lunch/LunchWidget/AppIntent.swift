import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Velg lokasjon" }
    
    @Parameter(title: "Lunsj hos", default: .fb38)
    var selectedLocation: Location
    
    func perform() async throws -> some IntentResult {
        // Update the shared UserDefaults
        UserDefaults.shared.set(selectedLocation.rawValue, forKey: "selectedLocation")
        print("Updated selectedLocation in UserDefaults: \(selectedLocation.rawValue)")
        
        // Return a successful result
        return .result()
    }
}
