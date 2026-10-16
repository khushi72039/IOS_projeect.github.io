import Foundation

struct User: Codable, Identifiable {
    var id: String
    var name: String
    var email: String
    var currencyCode: String
    var createdAt: Date
    var savingsGoalPercent: Double = 20
    var profileImageBase64: String? = nil
    var dailySpendingLimit: Double = 500   // Naya field - Widget ke liye
}
