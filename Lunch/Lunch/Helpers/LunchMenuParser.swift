import SwiftSoup

class LunchMenuParser {
    static func parse(html: String) throws -> [String: String] {
        var menu = [String: String]()
        let document = try SwiftSoup.parse(html)
        let columns = try document.select("div.sqs-html-content")
        
        // Select all columns that potentially contain a day's menu
        for column in columns {
            // Get the day name from the <h2> tag
            if let dayNameElement = try? column.select("h2").first(),
               let dayName = try? dayNameElement.text() {
                
                // Gather all <p> tags following the <h2> to form the menu
                let paragraphs = try column.select("p")
                var menuItems = ""

                for paragraph in paragraphs {
                    let text = try paragraph.text()
                    if !text.isEmpty {
                        // Add newline after )
                        // Remove empty space in "\n "
                        // Remove `(-)` from the menu item text
                        let cleanedText = text
                            .replacingOccurrences(of: ")", with: ")\n")
                            .replacingOccurrences(of: "\n ", with: "\n")
                            .replacingOccurrences(of: "(-)", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        menuItems += "\(cleanedText)\n"
                    }
                }

                // Add the day and its menu to the dictionary
                menu[dayName] = menuItems.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return menu
    }
}
