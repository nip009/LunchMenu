import SwiftUI
import SwiftSoup

class N58LunchMenuParser {
    static func parse(html: String) throws -> [String: DailyMenu] {
        var dailyMenus: [String: DailyMenu] = [:]
        
        let document = try SwiftSoup.parse(html)
        
        // Find all table rows except the header
        let rows = try document.select("table tr").dropFirst()

        for row in rows {
            // Extract the day name (e.g., "Mandag")
            let day = try row.select("a.dag").text()
            
            // Extract the main dish (Hovedrett)
            let varmMat = try row.select("a.hovedrett").text()
            
            // Extract the soup (Suppe)
            let dagensSuppe = try row.select("a.suppe").text()
            
            // Note: dagensSalat is not present in this HTML, set to an empty string
            let dagensSalat = ""
            
            // Create and store the DailyMenu
            let dailyMenu = DailyMenu(varmMat: varmMat, dagensSuppe: dagensSuppe, dagensSalat: dagensSalat)
            dailyMenus[day.uppercased()] = dailyMenu // Use uppercase day names as keys
        }
        
        return dailyMenus
    }
}

