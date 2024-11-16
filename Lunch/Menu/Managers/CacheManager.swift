import Foundation

class CacheManager {
    static let shared = CacheManager()
    private init() {}

    var cacheFileName: String {
        let selectedLocation = UserDefaults.standard.string(forKey: "selectedLocation") ?? "FB38"
        return "\(selectedLocation)_LunchMenuCache.json"
    }

    func saveToCache(data: String) {
        let cache = [
            "data": data,
            "timestamp": Date().timeIntervalSince1970 // Save the current timestamp
        ] as [String: Any]

        let fileURL = getCacheFileURL()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: cache, options: [])
            try jsonData.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save cache: \(error)")
        }
    }

    func loadFromCache() -> (data: String, isExpired: Bool)? {
        let fileURL = getCacheFileURL()
        do {
            let jsonData = try Data(contentsOf: fileURL)
            if let cache = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let data = cache["data"] as? String,
               let timestamp = cache["timestamp"] as? TimeInterval {
                
                // Check if the cache is expired
                let cacheDate = Date(timeIntervalSince1970: timestamp)
                let expirationDate = cacheDate.addingTimeInterval(3600 * 2) // 2 hours
                let isExpired = Date() > expirationDate
                
                return (data, isExpired)
            }
        } catch {
            print("Failed to load cache: \(error)")
        }
        return nil
    }
    
    func clearAllCaches() {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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

    private func getCacheFileURL() -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appendingPathComponent(cacheFileName)
    }
}

