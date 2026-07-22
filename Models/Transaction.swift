import Foundation

struct Transaction: Codable, Identifiable {
    var id: String
    var amount: Double
    var type: CategoryType        // .income ya .expense (Category wala hi enum reuse kiya)
    var categoryId: String
    var categoryName: String      // Display ke liye convenience field (baar baar category fetch na karna pade)
    var categoryIcon: String
    var categoryColorHex: String
    var date: Date
    var note: String?
    var updatedAt: Date
}
