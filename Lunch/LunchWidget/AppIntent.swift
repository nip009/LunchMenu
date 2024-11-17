import WidgetKit
import AppIntents
import SwiftUI

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Velg lokasjon" }
    
    @Parameter(title: "Lunsj hos", default: .n58)
    var selectedLocation: LocationOption
    
//    init() {
//        // Set the default value of `selectedLocation` from `UserDefaults.shared`
//        if let savedLocation = UserDefaults.shared.string(forKey: "selectedLocation"),
//           let locationOption = LocationOption(rawValue: savedLocation) {
//            self.selectedLocation = locationOption
//        } else {
//            self.selectedLocation = .fb38 // Fallback to default
//        }
//    }
    
    // Use `AppStorage` to ensure synchronization with UserDefaults.shared
    @AppStorage("selectedLocation", store: UserDefaults.shared) private var selectedLocationShared: String = "N58"
    
    init() {
        // On initialization, set `selectedLocation` to the value in `UserDefaults.shared`
        print("Shared select location: \(selectedLocationShared)")
        self.selectedLocation = LocationOption(rawValue: selectedLocationShared) ?? .n58
//        WidgetCenter.shared.reloadAllTimelines()
    }
    
    
    func perform() async throws -> some IntentResult {
        // Update the shared UserDefaults
        UserDefaults.shared.set(selectedLocation.rawValue, forKey: "selectedLocation")
        print("✅ Updated selectedLocation in UserDefaults: \(selectedLocation.rawValue)")
        
        WidgetCenter.shared.reloadAllTimelines()
        
        // Return a successful result
        return .result()
    }
}
