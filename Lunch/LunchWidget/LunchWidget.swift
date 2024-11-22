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
        let now = Date()
        let nextMondayAt8AM = getNextMonday(at: 8, from: now)

        // Load cached data and generate entries
        if let cachedData = CacheManager.shared.loadFromCache(for: configuration.selectedLocation.rawValue),
           let menuDict = parseMenu(cachedData.data, configuration: configuration) {
            
            // Generate timeline entries, accounting for after-1 PM logic
            let entries = generateWeeklyEntries(from: menuDict, startDate: now, configuration: configuration)
            return Timeline(entries: entries, policy: .after(nextMondayAt8AM))
        }

        return Timeline(entries: [], policy: .after(nextMondayAt8AM))
    }


    private func getNextMonday(at hour: Int, from date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.nextDate(
            after: date,
            matching: DateComponents(hour: hour, weekday: 2), // 2 = Monday
            matchingPolicy: .nextTime
        ) ?? date
    }

    private func createEntry(for date: Date, configuration: ConfigurationAppIntent) -> SimpleEntry {
        let calendar = Calendar.current
        let now = Date()

        // Determine the day offset based on the time
        let hour = calendar.component(.hour, from: now)
        let dayOffset = hour >= 13 ? 1 : 0 // Switch to tomorrow's menu after 1 PM

        // Calculate the target date
        let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now)!
        let dayName = DateFormatter.norwegianWeekday.string(from: targetDate).uppercased()

        // Retrieve the menu for the target day
        let cachedData = CacheManager.shared.loadFromCache(for: configuration.selectedLocation.rawValue)
        let menuDict = cachedData.flatMap { parseMenu($0.data, configuration: configuration) } ?? [:]
        let menu = WeekDay(rawValue: dayName).flatMap { menuDict[$0.rawValue] } ?? DailyMenu.noMenu

        return SimpleEntry(date: targetDate, day: dayName.capitalized, menu: menu, configuration: configuration)
    }

    private func generateWeeklyEntries(from menus: [String: DailyMenu], startDate: Date, configuration: ConfigurationAppIntent) -> [SimpleEntry] {
        let calendar = Calendar.current
        var entries: [SimpleEntry] = []
        let now = Date()

        // Determine if we should show today or tomorrow's menu based on time
        let hour = calendar.component(.hour, from: now)
        let startDayOffset = hour >= 13 ? 1 : 0

        // Generate entries for the rest of the week
        for offset in startDayOffset..<7 {
            guard let baseDate = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
            
            // Set the time to 1 PM for each day's entry
            guard let entryDate = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: baseDate) else { continue }
            
            let dayName = DateFormatter.norwegianWeekday.string(from: baseDate).uppercased()
            let menu = WeekDay(rawValue: dayName).flatMap { menus[$0.rawValue] } ?? DailyMenu.noMenu

            let entry = SimpleEntry(date: entryDate, day: dayName.capitalized, menu: menu, configuration: configuration)
            entries.append(entry)
        }

        return entries
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
