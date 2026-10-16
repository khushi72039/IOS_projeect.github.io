import Foundation
import FirebaseFirestore

class BudgetRepository {
    
    private let db = Firestore.firestore()
    
    private func budgetsCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("budgets")
    }
    
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
    
    func deleteBudget(userId: String, budgetId: String) async throws {
        try await budgetsCollection(userId: userId).document(budgetId).delete()
    }
    
    // MARK: - Seed Default Budgets (naye signup ke waqt)
    func seedDefaultBudgets(userId: String, categories: [Category]) async throws {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        let defaultAmounts: [String: Double] = [
            "Food": 5000, "Transport": 2000, "Entertainment": 1500,
            "Shopping": 3000, "Bills": 4000, "Health": 2000, "Other": 1000
        ]
        
        for category in categories where category.type == .expense {
            let amount = defaultAmounts[category.name] ?? 1000
            let budget = Budget(
                id: UUID().uuidString, categoryId: category.id, categoryName: category.name,
                categoryIcon: category.iconName, categoryColorHex: category.colorHex,
                monthlyLimit: amount, month: month, year: year, notifiedThresholds: []
            )
            try await setBudget(userId: userId, budget: budget)
        }
    }
    
    // MARK: - Update Notified Thresholds (jab notification bhej diya jaaye to yahan mark kar dete hain)
    func updateNotifiedThresholds(userId: String, budgetId: String, thresholds: [Int]) async throws {
        try await budgetsCollection(userId: userId).document(budgetId).updateData([
            "notifiedThresholds": thresholds
        ])
    }
    
}
