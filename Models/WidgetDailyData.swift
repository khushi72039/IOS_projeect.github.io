
import Foundation

struct WidgetDailyData: Codable {
    let monthLabel: String       // "September 2026"
    let dailyLimit: Double
    let dayPercentages: [Double] // Har din ke liye % (0 = kuch nahi kharcha, -1 = future din)
}
