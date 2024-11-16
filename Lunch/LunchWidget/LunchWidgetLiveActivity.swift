//
//  LunchWidgetLiveActivity.swift
//  LunchWidget
//
//  Created by Simen Lien on 16/11/2024.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LunchWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct LunchWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LunchWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension LunchWidgetAttributes {
    fileprivate static var preview: LunchWidgetAttributes {
        LunchWidgetAttributes(name: "World")
    }
}

extension LunchWidgetAttributes.ContentState {
    fileprivate static var smiley: LunchWidgetAttributes.ContentState {
        LunchWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: LunchWidgetAttributes.ContentState {
         LunchWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: LunchWidgetAttributes.preview) {
   LunchWidgetLiveActivity()
} contentStates: {
    LunchWidgetAttributes.ContentState.smiley
    LunchWidgetAttributes.ContentState.starEyes
}
