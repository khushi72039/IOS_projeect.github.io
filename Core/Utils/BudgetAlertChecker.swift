import Foundation

class BudgetAlertChecker {
    
    static let shared = BudgetAlertChecker()
    private init() {}
    
    private let budgetRepository = BudgetRepository()
    private let transactionRepository = TransactionRepository()
    
    private let thresholds = [75, 90, 100]
    
    // MARK: - Check Thresholds for a Specific Category (naya expense add hone ke baad call hota hai)
    func checkAndNotify(userId: String, categoryId: String) async {
        // Agar user ne app settings me notifications off ki hain, to kuch mat karo
        guard NotificationService.shared.isEnabledInAppSettings else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        do {
            // Us category ka is month ka budget dhoondo
            let budgets = try await budgetRepository.fetchBudgets(userId: userId, month: month, year: year)
            guard let budget = budgets.first(where: { $0.categoryId == categoryId }) else { return }
            guard budget.monthlyLimit > 0 else { return }
            
            // Us category me is month ab tak kitna kharch hua hai
            let allTransactions = try await transactionRepository.fetchTransactions(userId: userId)
            let spent = allTransactions
                .filter { $0.categoryId == categoryId && $0.type == .expense && calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
            
            let percent = (spent / budget.monthlyLimit) * 100
            
            // Sabse bada threshold dhoondo jo cross ho chuka hai lekin abhi tak notify nahi hua
            var updatedThresholds = budget.notifiedThresholds
            var newlyTriggeredThreshold: Int? = nil
            
            for threshold in thresholds {
                if percent >= Double(threshold) && !updatedThresholds.contains(threshold) {
                    newlyTriggeredThreshold = threshold
                    updatedThresholds.append(threshold)
                }
            }
            
            guard let threshold = newlyTriggeredThreshold else { return }
            
            // Notification bhejo
            let title: String
            let body: String
            
            if threshold >= 100 {
                title = "Budget Exceeded! 🚨"
                body = "\(budget.categoryName) has exceeded its monthly budget of ₹\(Int(budget.monthlyLimit))"
            } else {
                title = "Budget Alert ⚠️"
                body = "\(budget.categoryName) has reached \(threshold)% of its ₹\(Int(budget.monthlyLimit)) monthly budget"
            }
            
            NotificationService.shared.sendNotification(title: title, body: body)
            
            // Firestore me update kar do taaki dobara same alert na aaye
            try await budgetRepository.updateNotifiedThresholds(userId: userId, budgetId: budget.id, thresholds: updatedThresholds)
            
        } catch {
            print("Budget alert check failed: \(error.localizedDescription)")
        }
    }
}
