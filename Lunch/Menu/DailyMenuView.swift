import SwiftUI

struct DailyMenuView: View {
    @AppStorage("showDagensVarmMat") private var showDagensVarmMat: Bool = true
    @AppStorage("showDagensSuppe") private var showDagensSuppe: Bool = true
    @AppStorage("showDagensSalat") private var showDagensSalat: Bool = false
    
    let day: WeekDay
    let menu: DailyMenu
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(day.rawValue)
                .font(.title2)
                .bold()
            if showDagensVarmMat && menu.varmMat.isEmpty == false {
                Text(menu.varmMat)
                    .font(.body)
            }
            
            if showDagensSuppe && menu.dagensSuppe.isEmpty == false {
                Text(menu.dagensSuppe)
                    .font(.body)
            }
            
            if showDagensSalat && menu.dagensSalat.isEmpty == false {
                Text(menu.dagensSalat)
                    .font(.body)
            }
            
            Divider()
        }
        .padding(.horizontal)
    }
}
