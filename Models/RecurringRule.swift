import Foundation

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct RecurringRule: Codable, Identifiable {
    var id: String
    var frequency: RecurringFrequency
    var startDate: Date
    var lastGeneratedDate: Date
    var isActive: Bool
    
    // Template details - naya transaction inhi se banega
    var amount: Double
    var type: CategoryType
    var categoryId: String
    var categoryName: String
    var categoryIcon: String
    var categoryColorHex: String
    var note: String?
}
