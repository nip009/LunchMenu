import Foundation
import SwiftUI
import SwiftSoup

// An app that shows the lunch menu at FB38 in Fyllingsdalen or N58 in Nøstegaten 😋
struct ContentView: View {
    @Environment(\.openURL) private var openURL

    @AppStorage("showWholeMenu") private var showWholeMenu: Bool = true
    @AppStorage("showMenuPickerOnMainView") private var showMenuPickerOnMainView: Bool = false
    @AppStorage("showLocationPickerOnMainView") private var showLocationPickerOnMainView: Bool = false
    @AppStorage("showPayLinkOnMainView") private var showPayLinkOnMainView: Bool = false
    @AppStorage("selectedLocation") private var selectedLocation: String = "N58"
    
    @State private var lunchMenu: [String: DailyMenu] = [:]
    @State private var errorMessage: String?
    @State private var todayMenu: DailyMenu?
    
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
                            Picker("Location", selection: $selectedLocation) {
                                Text("FB38").tag("FB38")
                                Text("N58").tag("N58")
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
            .onAppear {
                fetchAndParseLunchMenu()
            }
            .refreshable {
                fetchAndParseLunchMenu()
            }
            .onChange(of: selectedLocation) {
                fetchAndParseLunchMenu()
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else if lunchMenu.isEmpty {
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
//                    Image(systemName: "creditcard.fill")
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
                if let dailyMenu = lunchMenu[day.rawValue] {
                    DailyMenuView(day: day, menu: dailyMenu)
                }
            }
        }
    }
    
    @ViewBuilder
    var todayMenuView: some View {
        if let today = currentDay(), let todayMenu = lunchMenu[today.rawValue] {
            DailyMenuView(day: today, menu: todayMenu)
        } else {
            Text("Ingen meny tilgjengelig i dag")
                .italic()
        }
    }
    
    func openPayLink() {
        let urlString = selectedLocation == "FB38" ? fb38PayURLString : n58PayURLString
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
    
    // MARK: - Functions

    func fetchAndParseLunchMenu() {
        // Try to load from cache
        if let cachedData = CacheManager.shared.loadFromCache() {
            if !cachedData.isExpired {
                parseAndSetMenu(cachedData.data)
                print("Loaded from cache")
                return
            } else {
                print("Cache expired")
            }
        }
        
        let fb38URLString = "https://fb38.squarespace.com/meny"
        let n58URLString = "https://drittserver.net/lunsj/"
        let urlString = selectedLocation == "FB38" ? fb38URLString : n58URLString

        // Fetch from the website
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data, let html = String(data: data, encoding: .utf8), !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                DispatchQueue.main.async {
                    errorMessage = "Received empty or invalid data from server."
                }
                return
            }

            // Cache the response if valid
            CacheManager.shared.saveToCache(data: html)
            print("Saved to cache")

            // Parse and update UI
            parseAndSetMenu(html)
        }
        task.resume()
    }
    
    private func parseFB38AndSetMenu(_ html: String) {
        do {
            let menu = try FB38LunchMenuParser.parse(html: html)
            DispatchQueue.main.async {
                self.lunchMenu = menu
                if let today = currentDay()?.rawValue {
                    self.todayMenu = menu[today]
                } else {
                    self.todayMenu = nil
                }
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                errorMessage = "Failed to parse HTML: \(error.localizedDescription)"
            }
        }
    }
    
    private func parseN58AndSetMenu(_ html: String) {
        do {
            let menu = try N58LunchMenuParser.parse(html: html)
            DispatchQueue.main.async {
                self.lunchMenu = menu
                if let today = currentDay()?.rawValue {
                    self.todayMenu = menu[today]
                } else {
                    self.todayMenu = nil
                }
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                errorMessage = "Failed to parse HTML: \(error.localizedDescription)"
            }
        }
    }
    
    private func parseAndSetMenu(_ html: String) {
        if selectedLocation == "FB38" {
            parseFB38AndSetMenu(html)
        } else if selectedLocation == "N58" {
            parseN58AndSetMenu(html)
        }
    }
    
    func currentDay() -> WeekDay? {
        return WeekDay.currentDay()
    }
}
