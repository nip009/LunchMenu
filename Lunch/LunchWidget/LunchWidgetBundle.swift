//
//  LunchWidgetBundle.swift
//  LunchWidget
//
//  Created by Simen Lien on 16/11/2024.
//

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
