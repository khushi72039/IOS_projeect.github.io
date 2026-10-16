import Foundation

class RecurringEngine {
    
    static let shared = RecurringEngine()
    private init() {}
    
    private let ruleRepository = RecurringRuleRepository()
    private let transactionRepository = TransactionRepository()
    
    // MARK: - Main Entry Point (app launch par call hota hai)
    func processRecurringRules(userId: String) async {
        do {
            let rules = try await ruleRepository.fetchAllRules(userId: userId)
            let activeRules = rules.filter { $0.isActive }
            
            for rule in activeRules {
                await generateDueTransactions(userId: userId, rule: rule)
            }
        } catch {
            print("Recurring engine error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Generate Transactions for a Single Rule
    private func generateDueTransactions(userId: String, rule: RecurringRule) async {
        let calendar = Calendar.current
        let today = Date()
        
        var nextDueDate = nextDate(after: rule.lastGeneratedDate, frequency: rule.frequency, calendar: calendar)
        var lastCreatedDate = rule.lastGeneratedDate
        var createdAny = false
        
        // Jab tak due dates aaj (ya aaj se pehle) tak hain, transactions banate raho
        // Safety limit: ek baar me max 60 transactions (taaki koi bug infinite loop na bana de)
        var safetyCounter = 0
        
        while nextDueDate <= today && safetyCounter < 60 {
            let newTransaction = Transaction(
                id: UUID().uuidString,
                amount: rule.amount,
                type: rule.type,
                categoryId: rule.categoryId,
                categoryName: rule.categoryName,
                categoryIcon: rule.categoryIcon,
                categoryColorHex: rule.categoryColorHex,
                date: nextDueDate,
                note: rule.note,
                receiptImageURL: nil,
                updatedAt: Date()
            )
            
            do {
                try await transactionRepository.addTransaction(userId: userId, transaction: newTransaction)
                createdAny = true
                lastCreatedDate = nextDueDate
            } catch {
                print("Failed to auto-generate recurring transaction: \(error.localizedDescription)")
                break
            }
            
            nextDueDate = nextDate(after: nextDueDate, frequency: rule.frequency, calendar: calendar)
            safetyCounter += 1
        }
        
        // Agar koi nayi transaction bani ho, to rule ki lastGeneratedDate update kar do
        if createdAny {
            try? await ruleRepository.updateLastGeneratedDate(userId: userId, ruleId: rule.id, date: lastCreatedDate)
        }
    }
    
    // MARK: - Calculate Next Due Date based on Frequency
    private func nextDate(after date: Date, frequency: RecurringFrequency, calendar: Calendar) -> Date {
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}
