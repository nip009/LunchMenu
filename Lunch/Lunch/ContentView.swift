import Foundation
import SwiftUI
import SwiftSoup

struct ContentView: View {
    @State private var lunchMenu: [String: String] = [:]
    @State private var errorMessage: String?
    @State private var todayMenu: String?
    
    @State private var showWholeMenu = false
    
    let dayOrder = ["MANDAG", "TIRSDAG", "ONSDAG", "TORSDAG", "FREDAG"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                content
            }
            .navigationTitle("FB38 Lunsj")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                .padding()
            } else if showWholeMenu {
                wholeMenuView
            } else {
                todayMenuView
            }
        }
        .padding(.horizontal)
    }
    
    var wholeMenuView: some View {
        ForEach(dayOrder.filter { lunchMenu.keys.contains($0) }, id: \.self) { day in
            VStack(alignment: .center) {
                Text(day)
                    .font(.headline)
                Text(lunchMenu[day] ?? "No menu available")
                    .font(.subheadline)
                Divider()
            }
        }
    }
    
    var todayMenuView: some View {
        VStack {
            if let todayMenu = todayMenu {
                VStack(alignment: .leading) {
                    Text(currentDay())
                        .font(.headline)
                    Text(todayMenu)
                        .font(.subheadline)
                }
            } else {
                Text("No menu available for today.")
                    .italic()
            }
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
                self.todayMenu = menu[currentDay()]
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                errorMessage = "Failed to parse HTML: \(error.localizedDescription)"
            }
        }
    }

    func currentDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "no_NO")
        let dayName = formatter.string(from: Date())
        
        switch dayName.lowercased() {
        case "mandag": return "MANDAG"
        case "tirsdag": return "TIRSDAG"
        case "onsdag": return "ONSDAG"
        case "torsdag": return "TORSDAG"
        case "fredag": return "FREDAG"
        default: return ""
        }
    }
    
}
