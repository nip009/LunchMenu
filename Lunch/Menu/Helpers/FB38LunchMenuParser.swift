import SwiftSoup

class FB38LunchMenuParser {
    static func parse(html: String) throws -> [String: DailyMenu] {
        var menu = [String: DailyMenu]()
        let document = try SwiftSoup.parse(html)

        // Select all columns that potentially contain a day's menu
        let columns = try document.select("div.sqs-html-content")

        for column in columns {
            // Get the day name from the <h2> tag
            if let dayNameElement = try? column.select("h2").first(),
               let dayName = try? dayNameElement.text() {

                // Gather all text content for this day
                let fullText = try column.text()

                // Extract each category and its content
                let varmMat = extractCategory(from: fullText, category: "VARMMAT", nextCategory: "DAGENS SUPPE")
                let dagensSuppe = extractCategory(from: fullText, category: "DAGENS SUPPE", nextCategory: "DAGENS SALAT")
                let dagensSalat = extractCategory(from: fullText, category: "DAGENS SALAT", nextCategory: nil)

                // Add the day's menu to the dictionary
                menu[dayName] = DailyMenu(varmMat: varmMat, dagensSuppe: dagensSuppe, dagensSalat: dagensSalat)
            }
        }

        return menu
    }
}



private func extractCategory(from text: String, category: String, nextCategory: String?) -> String {
    // Find the start of the category
    guard let categoryRange = text.range(of: category) else { return "" }

    // Determine the end of the category's content
    let endRange: Range<String.Index>
    if let nextCategory = nextCategory, let nextCategoryRange = text.range(of: nextCategory) {
        endRange = nextCategoryRange.lowerBound..<nextCategoryRange.lowerBound
    } else {
        endRange = text.endIndex..<text.endIndex
    }

    // Extract the content between the category and the next category
    let contentRange = categoryRange.upperBound..<endRange.lowerBound
    let content = text[contentRange]
        .replacingOccurrences(of: "(-)", with: "\n")
        .replacingOccurrences(of: "\\s*\\([^)]*\\)", with: "\n", options: .regularExpression) // Remove everything in parentheses. Replace it with newline.
        .replacingOccurrences(of: "\n ", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return content
}
