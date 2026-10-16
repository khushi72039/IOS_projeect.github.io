import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct DailyBudgetEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetDailyData?
}

// MARK: - Timeline Provider
struct DailyBudgetProvider: TimelineProvider {
    private let appGroupID = "group.com.sahul.Finace-tracker-khushi"
    
    func placeholder(in context: Context) -> DailyBudgetEntry {
        DailyBudgetEntry(date: Date(), widgetData: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DailyBudgetEntry) -> Void) {
        completion(DailyBudgetEntry(date: Date(), widgetData: loadData()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyBudgetEntry>) -> Void) {
        let entry = DailyBudgetEntry(date: Date(), widgetData: loadData())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadData() -> WidgetDailyData? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID),
              let data = sharedDefaults.data(forKey: "widgetDailyData"),
              let decoded = try? JSONDecoder().decode(WidgetDailyData.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// MARK: - Colors (Claude jaisa Terracotta shade, widget target me independently defined)
enum WidgetColors {
    static let accent = Color(red: 0.80, green: 0.47, blue: 0.36)   // Terracotta
    static let emptyDay = Color.gray.opacity(0.15)
    static let futureDay = Color.gray.opacity(0.06)
    static let overLimit = Color(red: 0.91, green: 0.30, blue: 0.24) // Red
}

// MARK: - Widget View
struct FinanceTrackerWidgetEntryView: View {
    var entry: DailyBudgetProvider.Entry
    
    var body: some View {
        if let data = entry.widgetData {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(data.monthLabel)
                        .font(.caption.bold())
                    Spacer()
                    Text("Limit: ₹\(Int(data.dailyLimit))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(0..<data.dayPercentages.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorFor(percentage: data.dayPercentages[index]))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(12)
        } else {
            VStack(spacing: 6) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.title2)
                    .foregroundColor(WidgetColors.accent)
                Text("Open app to sync data")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    private func colorFor(percentage: Double) -> Color {
        if percentage < 0 {
            return WidgetColors.futureDay
        } else if percentage == 0 {
            return WidgetColors.emptyDay
        } else if percentage > 1.0 {
            return WidgetColors.overLimit
        } else if percentage <= 0.25 {
            return WidgetColors.accent.opacity(0.25)
        } else if percentage <= 0.5 {
            return WidgetColors.accent.opacity(0.5)
        } else if percentage <= 0.75 {
            return WidgetColors.accent.opacity(0.75)
        } else {
            return WidgetColors.accent
        }
    }
}

// MARK: - Widget Definition
struct FinanceTrackerWidget: Widget {
    let kind: String = "FinanceTrackerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyBudgetProvider()) { entry in
            FinanceTrackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Spending")
        .description("See your daily spending intensity for the month at a glance.")
        .supportedFamilies([.systemMedium])
    }
}
