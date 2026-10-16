//
//  FinanceTrackerWidgetLiveActivity.swift
//  FinanceTrackerWidget
//
//  Created by Mobile5 on 28/09/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FinanceTrackerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FinanceTrackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FinanceTrackerWidgetAttributes.self) { context in
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

extension FinanceTrackerWidgetAttributes {
    fileprivate static var preview: FinanceTrackerWidgetAttributes {
        FinanceTrackerWidgetAttributes(name: "World")
    }
}

extension FinanceTrackerWidgetAttributes.ContentState {
    fileprivate static var smiley: FinanceTrackerWidgetAttributes.ContentState {
        FinanceTrackerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FinanceTrackerWidgetAttributes.ContentState {
         FinanceTrackerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FinanceTrackerWidgetAttributes.preview) {
   FinanceTrackerWidgetLiveActivity()
} contentStates: {
    FinanceTrackerWidgetAttributes.ContentState.smiley
    FinanceTrackerWidgetAttributes.ContentState.starEyes
}
