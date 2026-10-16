import Foundation
import WidgetKit

class SharedDataManager {
    
    static let shared = SharedDataManager()
    private init() {}
    
    // Apna App Group ID yahan daala hai - jo hum pehle bana chuke hain
    private let appGroupID = "group.com.sahul.Finace-tracker-khushi"
    private let transactionRepository = TransactionRepository()
    
    // MARK: - Widget ke liye data calculate karke shared storage me save karna
    func syncWidgetData(userId: String, dailyLimit: Double) async {
        guard let allTransactions = try? await transactionRepository.fetchTransactions(userId: userId) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return }
        let daysInMonth = range.count
        
        var percentages = [Double](repeating: -1, count: daysInMonth)
        
        for day in 1...daysInMonth {
            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = day
            guard let dayDate = calendar.date(from: components) else { continue }
            
            // Agar yeh din abhi future me hai, to -1 (unknown) hi rehne do
            if dayDate > now && !calendar.isDateInToday(dayDate) { continue }
            
            let daySpend = allTransactions
                .filter { $0.type == .expense && calendar.isDate($0.date, inSameDayAs: dayDate) }
                .reduce(0) { $0 + $1.amount }
            
            percentages[day - 1] = dailyLimit > 0 ? (daySpend / dailyLimit) : 0
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let widgetData = WidgetDailyData(
            monthLabel: formatter.string(from: now),
            dailyLimit: dailyLimit,
            dayPercentages: percentages
        )
        
        if let encoded = try? JSONEncoder().encode(widgetData) {
            UserDefaults(suiteName: appGroupID)?.set(encoded, forKey: "widgetDailyData")
        }
        
        // Widget ko turant refresh hone ke liye bolo
        WidgetCenter.shared.reloadAllTimelines()
    }
}
