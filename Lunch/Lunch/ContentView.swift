import Foundation
import SwiftUI
import SwiftSoup

struct ContentView: View {
    @State private var lunchMenu: [String: DailyMenu] = [:]
    @State private var errorMessage: String?
    @State private var todayMenu: DailyMenu?
    
    @State private var showWholeMenu = false
    
    let refillCardURLString = "https://www.alreadyordered.no/fb38/content/uncode-lite_child/TemplateProductTable_pure.php"
    
    let dayOrder: [WeekDay] = WeekDay.allCases
    
    var body: some View {
        NavigationView {
            ScrollView {
                content
            }
            .scrollContentBackground(.hidden)
            .background(Color.blue.opacity(0.25).gradient)
            .navigationTitle("FB38 Lunsj")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: openRefillCardLink) {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("View Mode", selection: $showWholeMenu) {
                        Text("I dag").tag(false)
                        Text("Uke").tag(true)
                    }
                    .pickerStyle(.inline)
                }
            }
            .onAppear {
                fetchAndParseLunchMenu()
            }
            .refreshable {
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
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    var wholeMenuView: some View {
        VStack(spacing: 16) {
            ForEach(dayOrder, id: \.self) { day in
                if let dailyMenu = lunchMenu[day.rawValue] {
                    DailyMenuView(day: day, dailyMenu: dailyMenu)
                }
            }
        }
    }
    
    @ViewBuilder
    var todayMenuView: some View {
        if let today = currentDay(), let todayMenu = lunchMenu[today.rawValue] {
            DailyMenuView(day: today, dailyMenu: todayMenu)
        } else {
            Text("No menu available for today.")
                .italic()
        }
    }
    
    func openRefillCardLink() {
        if let url = URL(string: refillCardURLString) {
            UIApplication.shared.open(url)
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

        // Fetch from the website
        guard let url = URL(string: "https://fb38.squarespace.com/meny") else {
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

            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    errorMessage = "Failed to decode response"
                }
                return
            }

            // Cache the response
            CacheManager.shared.saveToCache(data: html)
            print("Saved to cache")

            // Parse and update UI
            parseAndSetMenu(html)
        }
        task.resume()
    }
    
    private func parseAndSetMenu(_ html: String) {
        do {
            let menu = try LunchMenuParser.parse(html: html)
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
    
    func currentDay() -> WeekDay? {
        return WeekDay.currentDay()
    }
}

enum WeekDay: String, CaseIterable {
    case mandag = "MANDAG"
    case tirsdag = "TIRSDAG"
    case onsdag = "ONSDAG"
    case torsdag = "TORSDAG"
    case fredag = "FREDAG"

    static func currentDay() -> WeekDay? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "no_NO")
        let dayName = formatter.string(from: Date()).lowercased()

        switch dayName {
        case "mandag": return .mandag
        case "tirsdag": return .tirsdag
        case "onsdag": return .onsdag
        case "torsdag": return .torsdag
        case "fredag": return .fredag
        default: return nil
        }
    }
}
