import SwiftUI

struct DailyMenuView: View {
    let day: WeekDay
    let dailyMenu: DailyMenu
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(day.rawValue)
                .font(.title2)
                .bold()
            Text(dailyMenu.varmMat)
                .font(.body)
            
            Text(dailyMenu.dagensSuppe)
                .font(.body)
            
            Divider()
        }
        .padding(.horizontal)
    }
}
