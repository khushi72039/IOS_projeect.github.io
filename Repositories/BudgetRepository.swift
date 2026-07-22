import Foundation
import FirebaseFirestore

class BudgetRepository {
    
    private let db = Firestore.firestore()
    
    private func budgetsCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("budgets")
    }
    
    // Naya budget set/save karne ke liye
    func setBudget(userId: String, budget: Budget) async throws {
        let data: [String: Any] = [
            "id": budget.id,
            "categoryId": budget.categoryId,
            "categoryName": budget.categoryName,
            "categoryIcon": budget.categoryIcon,
            "categoryColorHex": budget.categoryColorHex,
            "monthlyLimit": budget.monthlyLimit,
            "month": budget.month,
            "year": budget.year,
            "notifiedThresholds": budget.notifiedThresholds
        ]
        try await budgetsCollection(userId: userId).document(budget.id).setData(data)
    }
    
    // Current month/year ke saare budgets fetch karne ke liye
    func fetchBudgets(userId: String, month: Int, year: Int) async throws -> [Budget] {
        let snapshot = try await budgetsCollection(userId: userId)
            .whereField("month", isEqualTo: month)
            .whereField("year", isEqualTo: year)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let categoryId = data["categoryId"] as? String,
                  let categoryName = data["categoryName"] as? String,
                  let categoryIcon = data["categoryIcon"] as? String,
                  let categoryColorHex = data["categoryColorHex"] as? String,
                  let monthlyLimit = data["monthlyLimit"] as? Double,
                  let month = data["month"] as? Int,
                  let year = data["year"] as? Int else {
                return nil
            }
            let notifiedThresholds = data["notifiedThresholds"] as? [Int] ?? []
            
            return Budget(
                id: doc.documentID,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                categoryColorHex: categoryColorHex,
                monthlyLimit: monthlyLimit,
                month: month,
                year: year,
                notifiedThresholds: notifiedThresholds
            )
        }
    }
    
    // Budget delete karne ke liye
    func deleteBudget(userId: String, budgetId: String) async throws {
        try await budgetsCollection(userId: userId).document(budgetId).delete()
    }
}
