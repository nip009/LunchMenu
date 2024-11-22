import SwiftUI

struct SettingsView: View {
    @AppStorage("showWholeMenu") private var showWholeMenu: Bool = true
    @AppStorage("showMenuPickerOnMainView") private var showMenuPickerOnMainView: Bool = false
    @AppStorage("showLocationPickerOnMainView") private var showLocationPickerOnMainView: Bool = false
    @AppStorage("showPayLinkOnMainView") private var showPayLinkOnMainView: Bool = false
    @AppStorage("showDagensVarmMat") private var showDagensVarmMat: Bool = true
    @AppStorage("showDagensSuppe") private var showDagensSuppe: Bool = true
    @AppStorage("showDagensSalat") private var showDagensSalat: Bool = false
    @AppStorage("selectedLocation", store: UserDefaults.shared) private var selectedLocation: String = Location.n58.rawValue
    
    var body: some View {
        List {
            Section(header: Text("Lunsj hos")) {
                Menu {
                    Picker("Lunsj hos", selection: $selectedLocation) {
                        ForEach(Location.allCases, id: \.self) { location in
                            Text(location.displayName).tag(location.rawValue)
                        }
                    }
                } label: {
                    Label("\(selectedLocation)", systemImage: "fork.knife.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .foregroundStyle(.foreground)
                }
            }
            
            Section(header: Text("Visning")) {
                Menu {
                    Picker("Visning", selection: $showWholeMenu) {
                        Text("I dag").tag(false)
                        Text("Uke").tag(true)
                    }
                } label: {
                    Label("\(showWholeMenu ? "Uke" : "I dag")", systemImage: "calendar")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .foregroundStyle(.foreground)
                }
            }
            
            Section(header: Text("Mat")) {
                Toggle("Vis dagens varmmat", isOn: $showDagensVarmMat)
                Toggle("Vis dagens suppe", isOn: $showDagensSuppe)
                Toggle("Vis dagens salat", isOn: $showDagensSalat)
            }
            
            Section(header: Text("Hovedside innstillinger")) {
                Toggle("Vis visningsvelger", isOn: $showMenuPickerOnMainView)
                Toggle("Vis lokasjonsvelger", isOn: $showLocationPickerOnMainView)
                Toggle("Vis link til nettside", isOn: $showPayLinkOnMainView)
            }
            
            Section(header: Text("Annet")) {
                Button(action: CacheManager.shared.clearAllCaches) {
                    Text("Clear cache")
                        .foregroundStyle(.foreground)
                }
            }
        }
        .navigationTitle("Innstillinger")
        .navigationBarTitleDisplayMode(.inline)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .background(Color.blue.opacity(0.25).gradient)
    }
}
