struct DailyMenu {
    var varmMat: String
    var dagensSuppe: String
    var dagensSalat: String
    
    var varmMatDishes: [String] {
        varmMat.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}


extension DailyMenu {
    static var noMenu: DailyMenu {
        DailyMenu(
            varmMat: "Ingen meny tilgjengelig i dag",
            dagensSuppe: "",
            dagensSalat: ""
        )
    }
    
    static var mock: DailyMenu {
        DailyMenu(varmMat: "Pizza\nIndisk curry", dagensSuppe: "Tomatsuppe", dagensSalat: "Pasta salat")
    }
    
    static var fb38mockMenus: [String: DailyMenu] {
        return [
            WeekDay.mandag.rawValue : DailyMenu(
                varmMat: "Chili con Carne, tortilla chips, rømme og ris\nChili sin Carne",
                dagensSuppe: "Spinat suppe",
                dagensSalat: "Cæsarsalat"
            ),
            WeekDay.tirsdag.rawValue: DailyMenu(
                varmMat: "Karbonader med soppsaus, bakt potet og rotgrønnsaker\nPasta ala Vodka",
                dagensSuppe: "Indisk kyllingsuppe",
                dagensSalat: "Råkostsalat"
            ),
            WeekDay.onsdag.rawValue: DailyMenu(
                varmMat: "Kyllingtaco\nTortilla med panert fisk og coleslaw",
                dagensSuppe: "Kremet paprika suppe",
                dagensSalat: "Gresk salat"
            ),
            WeekDay.torsdag.rawValue: DailyMenu(
                varmMat: "Sei Cordon Bleu\n Ratatouille og hvitløksbrød",
                dagensSuppe: "Søtpotet suppe",
                dagensSalat: "Pastasalat"
            ),
            WeekDay.fredag.rawValue: DailyMenu(
                varmMat: "Marokkansk lammegryte med krydret couscous\nChicken fried rice",
                dagensSuppe: "Taco suppe",
                dagensSalat: "Quinoasalat"
            )
        ]
    }
    static var n58mockMenus: [String: DailyMenu] {
        return [
            WeekDay.mandag.rawValue : DailyMenu(
                varmMat: "Blabla",
                dagensSuppe: "Tomat suppe",
                dagensSalat: "Blomkål salat"
            ),
            WeekDay.tirsdag.rawValue: DailyMenu(
                varmMat: "Spaghetti\nPizza",
                dagensSuppe: "Blomkålsuppe",
                dagensSalat: "Pasta salat"
            ),
            WeekDay.onsdag.rawValue: DailyMenu(
                varmMat: "BlablaKyllingtaco\nTortilla med panert fisk og coleslaw",
                dagensSuppe: "Kremet paprika suppe",
                dagensSalat: "Gresk salat"
            ),
            WeekDay.torsdag.rawValue: DailyMenu(
                varmMat: "BlablaSei Cordon Bleu\n Ratatouille og hvitløksbrød",
                dagensSuppe: "Søtpotet suppe",
                dagensSalat: "Pastasalat"
            ),
            WeekDay.fredag.rawValue: DailyMenu(
                varmMat: "Marokkansk lammegryte med krydret couscous\nChicken fried rice",
                dagensSuppe: "Taco suppe",
                dagensSalat: "Quinoasalat"
            )
        ]
    }
}
