import Foundation

struct Transaction: Codable, Identifiable {
    var id: String
    var amount: Double
    var type: CategoryType
    var categoryId: String
    var categoryName: String
    var categoryIcon: String
    var categoryColorHex: String
    var date: Date
    var note: String?
    var receiptImageURL: String?
    var updatedAt: Date
}
