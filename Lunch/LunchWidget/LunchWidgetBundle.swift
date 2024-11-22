import WidgetKit
import SwiftUI

@main
struct LunchWidgetBundle: WidgetBundle {
    var body: some Widget {
        LunchWidget()
        LunchWidgetControl()
        LunchWidgetLiveActivity()
    }
}
