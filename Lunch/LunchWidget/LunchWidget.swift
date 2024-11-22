import WidgetKit
import AppIntents
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), day: WeekDay.friday.rawValue, menu: DailyMenu.mock, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        if let cachedData = CacheManager.shared.loadFromCache(for: configuration.selectedLocation.rawValue),
            let today = WeekDay.currentDay() {
            let menuDict = parseMenu(cachedData.data, configuration: configuration)
            let menu = menuDict?[today.rawValue] ?? DailyMenu.mock
            return SimpleEntry(date: Date(), day: today.rawValue, menu: menu, configuration: configuration)
        }
        
        // Fallback to mock data
        return SimpleEntry(date: Date(), day: WeekDay.currentDay()?.rawValue ?? WeekDay.monday.rawValue, menu: DailyMenu.mock, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let calendar = Calendar.current
        let now = Date()
        
        // Determine next Monday at 8 AM
        let nextMondayAt8AM = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 8, weekday: 2), // 2 = Monday
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86400) // Default to 24 hours later if calculation fails

        if let cachedData = CacheManager.shared.loadFromCache(for: configuration.selectedLocation.rawValue),
           let menu = parseMenu(cachedData.data, configuration: configuration) {
            
            // Generate entries from cached data
            let entries = generateEntries(from: menu, configuration: configuration)
            
            return Timeline(entries: entries, policy: .after(nextMondayAt8AM))
        }

        return Timeline(entries: [], policy: .after(nextMondayAt8AM))
    }

}

func parseMenu(_ html: String, configuration: ConfigurationAppIntent) -> [String: DailyMenu]? {
    guard let location = Location(rawValue: configuration.selectedLocation.rawValue) else {
        print("selectedLocation is not supported: \(configuration.selectedLocation.rawValue)")
        return [:]
    }
    
    if location == .fb38 {
        return parseFB38Menu(html)
    } else if location == .n58 {
        return parseN58Menu(html)
    }
    print("Parsing selectedLocation \(location.rawValue) is not handled.")
    return [:]
 }

private func parseFB38Menu(_ html: String) -> [String: DailyMenu]? {
    do {
        let menu = try FB38LunchMenuParser.parse(html: html)
        return menu
    } catch {
        DispatchQueue.main.async {
            print("Failed to parse HTML: \(error.localizedDescription)")
        }
    }
    return nil
}

private func parseN58Menu(_ html: String) -> [String: DailyMenu]? {
    do {
        let menu = try N58LunchMenuParser.parse(html: html)
        return menu
    } catch {
        DispatchQueue.main.async {
            print("Failed to parse HTML: \(error.localizedDescription)")
        }
    }
    return nil
}

func generateEntries(from menus: [String: DailyMenu], configuration: ConfigurationAppIntent) -> [SimpleEntry] {
    var entries: [SimpleEntry] = []
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let todayWeekday = calendar.component(.weekday, from: today) // 1 is Sunday, 2 is Monday, etc.
    
    // Calculate the start of the week (Monday)
    let startOfWeek = calendar.date(byAdding: .day, value: todayWeekday == 1 ? -6 : -(todayWeekday - 2), to: today)!
    
    for offset in 0..<7 {
        guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { continue }
        
        // Get the weekday name in Norwegian
        let dayName = DateFormatter.norwegianWeekday.string(from: date).uppercased()
        
        // Use the WeekDay enum to find the menu
        let menu = WeekDay(rawValue: dayName).flatMap { menus[$0.rawValue] } ?? .noMenu
        
        entries.append(
            SimpleEntry(
                date: date,
                day: dayName.capitalized,
                menu: menu,
                configuration: configuration
            )
        )
    }
    
    return entries
}



struct SimpleEntry: TimelineEntry {
    let date: Date
    let day: String
    let menu: DailyMenu
    let configuration: ConfigurationAppIntent
}

struct LunchWidgetEntryView : View {
    var entry: Provider.Entry
    
    var menu: DailyMenu { entry.menu }
    var location: Location? { Location(rawValue: entry.configuration.selectedLocation.rawValue) }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(entry.day.capitalized)")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    Text("\(location?.displayName ?? "")")
                        .font(.title2)
                        .bold()
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(location == .fb38
                                      ?  Color.orange
                                      : Color.gray.opacity(0.5))
                        )
                }
                Group {
                    Text(menu.varmMat)
//                    ForEach(menu.varmMatDishes, id: \.self) { varmMat in
//                        Text(varmMat)
//                    }
                    Text(menu.dagensSuppe)
//                    Text(menu.dagensSalat)
                }
                .font(.headline)
                
            }
            Spacer()
        }
    }
}

struct LunchWidget: Widget {
    let kind: String = "LunchWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            LunchWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.blue.opacity(0.25)
                }
        }
        .configurationDisplayName("Lunsj Widget")
        .description("Viser dagens meny")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    LunchWidget()
} timeline: {
    SimpleEntry(date: .now, day: WeekDay.monday.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.monday.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, day: WeekDay.tuesday.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.tuesday.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, day: WeekDay.wednesday.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.wednesday.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, day: WeekDay.thursday.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.thursday.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, day: WeekDay.friday.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.friday.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
}
