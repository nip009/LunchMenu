import Foundation
import WidgetKit

// The widget has to send in selectedLocation manually, because the widget can't update UserDefaults reliably when it's edited.

// Data shared through App Group needs to be sent through UserDefaults with this suiteName
let appGroupID = "group.com.example.share.token"

extension UserDefaults {
    static let shared = UserDefaults(suiteName: appGroupID)!
}

class CacheManager {
    static let shared = CacheManager()
    private init() {}
    
    func cacheFileName(for selectedLocation: String? = nil) -> String {
        let selectedLocation = selectedLocation ?? UserDefaults.shared.string(forKey: "selectedLocation") ?? "N58"
        return "\(selectedLocation)_LunchMenuCache.json"
    }

    func saveToCache(data: String) {
        guard !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Error: Attempted to save empty or invalid data to cache.")
            return
        }
        
        let cache = [
            "data": data,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        let fileURL = getCacheFileURL()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: cache, options: [])
            try jsonData.write(to: fileURL, options: .atomic)
            print("Saved data to cache at \(fileURL). Calling WidgetCenter.shared.reloadAllTimelines()")
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save cache: \(error)")
        }
    }

    func loadFromCache(for selectedLocation: String? = nil) -> (data: String, isExpired: Bool)? {
        if let selectedLocation {
            print("From Widget: Set selectedLoaction to \(selectedLocation)")
            UserDefaults.shared.set(selectedLocation, forKey: "selectedLocation")
        }
        let fileURL = getCacheFileURL(for: selectedLocation)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Cache file does not exist at \(fileURL)")
            return nil
        }
        print("Cache exists for \(selectedLocation)")
        
        do {
            let jsonData = try Data(contentsOf: fileURL)
            if let cache = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let data = cache["data"] as? String,
               let timestamp = cache["timestamp"] as? TimeInterval {
                
                let cacheDate = Date(timeIntervalSince1970: timestamp)
                let expirationDate = cacheDate.addingTimeInterval(3600 * 2) // 2 hours
                let isExpired = Date() > expirationDate
                
                return (data, isExpired)
            } else {
                print("Warning: Cache data is empty or invalid.")
            }
        } catch {
            print("Failed to load cache: \(error)")
        }
        return nil
    }
    
    func clearAllCaches() {
        guard let cachesDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("Failed to access shared App Group directory.")
            return
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: cachesDirectory, includingPropertiesForKeys: nil)

            for file in files {
                if file.lastPathComponent.hasSuffix("_LunchMenuCache.json") {
                    try FileManager.default.removeItem(at: file)
                    print("Cleared cache: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("Failed to clear caches: \(error)")
        }
    }

    private func getCacheFileURL(for selectedLocation: String? = nil) -> URL {
        guard let cachesDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Failed to access shared App Group directory.")
        }
        return cachesDirectory.appendingPathComponent(cacheFileName(for: selectedLocation))
    }
}

