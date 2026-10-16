//
//  FinanceTrackerWidgetBundle.swift
//  FinanceTrackerWidget
//
//  Created by Mobile5 on 28/09/26.
//

import WidgetKit
import SwiftUI

@main
struct FinanceTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        FinanceTrackerWidget()
        FinanceTrackerWidgetControl()
        FinanceTrackerWidgetLiveActivity()
    }
}
