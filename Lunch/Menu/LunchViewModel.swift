import Foundation
import SwiftUI
import Combine

class LunchViewModel: ObservableObject {
    @AppStorage("selectedLocation", store: UserDefaults.shared) private var selectedLocation: String = Location.n58.rawValue
    
    @Published var lunchMenu: [String: DailyMenu] = [:]
    @Published var errorMessage: String?
    @Published var todayMenu: DailyMenu?

    private var cancellables = Set<AnyCancellable>()
    
    func fetchAndParseLunchMenu() {
        if tryToLoadFromCache(for: selectedLocation) {
            return
        }
        
        let fb38URLString = "https://fb38.squarespace.com/meny"
        let n58URLString = "https://drittserver.net/lunsj/"
        
        guard let location = Location(rawValue: selectedLocation) else { return }
        let urlString = location == .fb38 ? fb38URLString : n58URLString

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                guard let html = String(data: output.data, encoding: .utf8), !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw URLError(.cannotDecodeContentData)
                }
                return html
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to fetch menu. \(error.localizedDescription)"
                    }
                }
            } receiveValue: { [weak self] html in
                guard let self = self else { return }
                CacheManager.shared.saveToCache(data: html, for: selectedLocation)
                print("Saved to cache")
                
                self.parseAndSetMenu(html)
            }
            .store(in: &cancellables)
    }
    
    private func parseAndSetMenu(_ html: String) {
        guard let location = Location(rawValue: selectedLocation) else { return }
        if location == .fb38 {
            parseFB38AndSetMenu(html)
        } else if location == .n58 {
            parseN58AndSetMenu(html)
        }
    }
    
    private func parseN58AndSetMenu(_ html: String) {
        do {
            let menu = try N58LunchMenuParser.parse(html: html)
            DispatchQueue.main.async {
                self.lunchMenu = menu
                if let today = WeekDay.currentDay()?.rawValue {
                    self.todayMenu = menu[today]
                } else {
                    self.todayMenu = nil
                }
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to parse HTML: \(error.localizedDescription)"
            }
        }
    }
    
    private func parseFB38AndSetMenu(_ html: String) {
        do {
            let menu = try FB38LunchMenuParser.parse(html: html)
            DispatchQueue.main.async {
                    self.lunchMenu = menu
                    if let today = WeekDay.currentDay()?.rawValue {
                        self.todayMenu = menu[today]
                    } else {
                        self.todayMenu = nil
                    }
                    self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to parse HTML: \(error.localizedDescription)"
            }
        }
    }
    
    private func tryToLoadFromCache(for selectedLocation: String) -> Bool {
        if let cachedData = CacheManager.shared.loadFromCache(for: selectedLocation) {
            if !cachedData.isExpired {
                parseAndSetMenu(cachedData.data)
                print("Loaded from cache")
                return true
            }
        }
        print("Cache expired")
        return false
    }
}
