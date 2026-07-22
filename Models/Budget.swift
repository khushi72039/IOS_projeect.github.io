
import Foundation

struct Budget: Codable, Identifiable {
    var id: String
    var categoryId: String
    var categoryName: String
    var categoryIcon: String
    var categoryColorHex: String
    var monthlyLimit: Double
    var month: Int
    var year: Int
    var notifiedThresholds: [Int]   // [75, 90, 100] me se jo already notify ho chuke hain
}
