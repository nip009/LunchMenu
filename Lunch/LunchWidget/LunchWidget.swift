import WidgetKit
import AppIntents
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), day: WeekDay.fredag.rawValue, menu: DailyMenu.mock, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        if let cachedData = CacheManager.shared.loadFromCache(),
            let today = WeekDay.currentDay() {
            let menuDict = parseMenu(cachedData.data, configuration: configuration)
            let menu = menuDict?[today.rawValue] ?? DailyMenu.mock
            return SimpleEntry(date: Date(), day: today.rawValue, menu: menu, configuration: configuration)
        }
        
        // Fallback to mock data
        return SimpleEntry(date: Date(), day: WeekDay.currentDay()?.rawValue ?? WeekDay.mandag.rawValue, menu: DailyMenu.mock, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        if let cachedData = CacheManager.shared.loadFromCache(),
           let menu = parseMenu(cachedData.data, configuration: configuration){
            let entries = generateEntries(from: menu, configuration: configuration)
            
            // Update timeline to refresh next Monday at 7 AM or the next day
            let nextUpdate = Calendar.current.nextDate(
                after: Date(), // TODO: Start of day?
                matching: DateComponents(hour: 7, weekday: 2),
                matchingPolicy: .nextTime
            ) ?? Date().addingTimeInterval(86400)
            return Timeline(entries: entries, policy: .after(nextUpdate))
        }
        
        // Return empty entries if cache is not available
        let entries: [SimpleEntry] = []
        return Timeline(entries: entries, policy: .atEnd)
    }
}

func parseMenu(_ html: String, configuration: ConfigurationAppIntent) -> [String: DailyMenu]? {
    if configuration.selectedLocation.rawValue == "FB38" {
        return parseFB38Menu(html)
    } else {
        return parseN58Menu(html)
    }
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
    var date = calendar.startOfDay(for: Date())

    for weekday in WeekDay.orderedDays {
        if let menu = menus[weekday.rawValue] {
            let entry = SimpleEntry(
                date: date,
                day: weekday.rawValue,
                menu: menu,
                configuration: configuration
            )
            entries.append(entry)

            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
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

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(entry.day.capitalized)")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    Text("\(entry.configuration.selectedLocation.rawValue)")
                        .font(.title2)
                        .bold()
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(entry.configuration.selectedLocation.rawValue == "FB38"
                                      ?  Color.orange
                                      : Color.gray.opacity(0.5))
                        )
                }
                Group {
                    ForEach(menu.varmMatDishes, id: \.self) { varmMat in
                        Text(varmMat)
                    }
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
    SimpleEntry(date: .now, day: WeekDay.mandag.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.mandag.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, day: WeekDay.tirsdag.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.tirsdag.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, day: WeekDay.onsdag.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.onsdag.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, day: WeekDay.torsdag.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.torsdag.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, day: WeekDay.fredag.rawValue, menu: DailyMenu.fb38mockMenus[WeekDay.fredag.rawValue] ?? DailyMenu.mock, configuration: ConfigurationAppIntent())
}
