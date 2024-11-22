import Foundation
import SwiftUI
import SwiftSoup

// An app that shows the lunch menu at FB38 in Fyllingsdalen or N58 in Nøstegaten 😋
struct LunchView: View {
    @StateObject private var viewModel = LunchViewModel()
    
    @Environment(\.openURL) private var openURL
    @AppStorage("showWholeMenu") private var showWholeMenu: Bool = true
    @AppStorage("showMenuPickerOnMainView") private var showMenuPickerOnMainView: Bool = false
    @AppStorage("showLocationPickerOnMainView") private var showLocationPickerOnMainView: Bool = false
    @AppStorage("showPayLinkOnMainView") private var showPayLinkOnMainView: Bool = false
    @AppStorage("selectedLocation", store: UserDefaults.shared) private var selectedLocation: String = Location.n58.rawValue
    
    let fb38PayURLString = "https://www.alreadyordered.no/fb38/content/uncode-lite_child/TemplateProductTable_pure.php"
    let n58PayURLString = "https://www.goldbyopen.no/nostegaten58/content/uncode-lite_child/TemplateProductTable_pure.php"
    
    let dayOrder: [WeekDay] = WeekDay.allCases
    
    var body: some View {
        NavigationStack {
            ScrollView {
                content
            }
            .scrollContentBackground(.hidden)
            .background(Color.blue.opacity(0.25).gradient)
            .navigationTitle("\(selectedLocation) Meny")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onAppear {
                viewModel.fetchAndParseLunchMenu()
            }
            .refreshable {
                viewModel.fetchAndParseLunchMenu()
            }
            .onChange(of: selectedLocation) {
                viewModel.fetchAndParseLunchMenu()
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        VStack {
            if let errorMessage = viewModel.errorMessage {
                Text("\(errorMessage)")
                    .foregroundColor(.red)
            } else if viewModel.lunchMenu.isEmpty {
                VStack(spacing: 16) {
                    ProgressView("Henter lunsjmeny...")
                        .padding()
                }
            } else if showWholeMenu {
                wholeMenuView
            } else {
                todayMenuView
            }
            
            if showPayLinkOnMainView {
                Button(action: openPayLink) {
                    Label("Nettside", systemImage: "creditcard.fill")
                        .foregroundStyle(.foreground)
                        .padding(.vertical, 12)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    var wholeMenuView: some View {
        VStack(spacing: 16) {
            ForEach(dayOrder, id: \.self) { day in
                if let dailyMenu = viewModel.lunchMenu[day.rawValue] {
                    DailyMenuView(day: day, menu: dailyMenu)
                }
            }
        }
    }
    
    @ViewBuilder
    var todayMenuView: some View {
        if let today = WeekDay.currentDay(), let todayMenu = viewModel.lunchMenu[today.rawValue] {
            DailyMenuView(day: today, menu: todayMenu)
        } else {
            Text("Ingen meny tilgjengelig")
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: openPayLink) {
                Image(systemName: "creditcard.fill")
                    .foregroundStyle(.foreground)
            }
        }
        
        if showMenuPickerOnMainView {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("View Mode", selection: $showWholeMenu) {
                        Text("I dag").tag(false)
                        Text("Uke").tag(true)
                    }
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(.foreground)
                }
            }
        }
        
        if showLocationPickerOnMainView {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Lunsj hos", selection: $selectedLocation) {
                        ForEach(Location.allCases, id: \.self) { location in
                            Text(location.displayName).tag(location.rawValue)
                        }
                    }
                } label: {
                    Image(systemName: "fork.knife.circle.fill")
                        .foregroundStyle(.foreground)
                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape")
                    .foregroundStyle(.foreground)
            }
        }
    }
    
    // MARK: - Functions
    
    func openPayLink() {
        guard let location = Location(rawValue: selectedLocation) else { return }
        let urlString = location == .fb38 ? fb38PayURLString : n58PayURLString
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
}
