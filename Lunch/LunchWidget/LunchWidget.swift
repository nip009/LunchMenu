import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), day: WeekDay.fredag.rawValue, menu: DailyMenu.mock, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), day: WeekDay.fredag.rawValue, menu: DailyMenu.mock, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entries: [SimpleEntry] = generateEntries(from: DailyMenu.mockMenus)
        return Timeline(entries: entries, policy: .atEnd)
    }
}

func generateEntries(from menus: [String: DailyMenu]) -> [SimpleEntry] {
    var entries: [SimpleEntry] = []
    let calendar = Calendar.current
    var date = calendar.startOfDay(for: Date())

    for weekday in WeekDay.orderedDays {
        if let menu = menus[weekday.rawValue] {
            let entry = SimpleEntry(date: date, day: weekday.rawValue, menu: menu, configuration: ConfigurationAppIntent())
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
    @AppStorage("selectedLocation") private var selectedLocation: String = "N58"
    
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
                    
                    Text("\(selectedLocation)")
                        .font(.title2)
                        .bold()
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedLocation == "FB38" ?  Color.orange : Color.gray.opacity(0.5))
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

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemMedium) {
    LunchWidget()
} timeline: {
    SimpleEntry(date: .now, day: WeekDay.mandag.rawValue, menu: DailyMenu.mockMenus[WeekDay.mandag.rawValue] ?? DailyMenu.mock, configuration: .smiley)
    SimpleEntry(date: .now, day: WeekDay.tirsdag.rawValue, menu: DailyMenu.mockMenus[WeekDay.tirsdag.rawValue] ?? DailyMenu.mock, configuration: .starEyes)
    SimpleEntry(date: .now, day: WeekDay.onsdag.rawValue, menu: DailyMenu.mockMenus[WeekDay.onsdag.rawValue] ?? DailyMenu.mock, configuration: .starEyes)
    SimpleEntry(date: .now, day: WeekDay.torsdag.rawValue, menu: DailyMenu.mockMenus[WeekDay.torsdag.rawValue] ?? DailyMenu.mock, configuration: .starEyes)
    SimpleEntry(date: .now, day: WeekDay.fredag.rawValue, menu: DailyMenu.mockMenus[WeekDay.fredag.rawValue] ?? DailyMenu.mock, configuration: .starEyes)
}
