import Foundation

@MainActor
class BudgetViewModel: ObservableObject {
    
    @Published var budgetItems: [BudgetProgress] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var toastMessage: String? = nil
    
    private let budgetRepository = BudgetRepository()
    private let transactionRepository = TransactionRepository()
    private let categoryRepository = CategoryRepository()
    private var userId: String?
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    // MARK: - Load Budgets with Spent Calculation
    func loadBudgets() async {
        guard let userId = userId else { return }
        isLoading = true
        
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        do {
            // Sirf expense categories par budget set hota hai
            let categories = try await categoryRepository.fetchCategories(userId: userId)
            let expenseCategories = categories.filter { $0.type == .expense }
            
            let budgets = try await budgetRepository.fetchBudgets(userId: userId, month: currentMonth, year: currentYear)
            
            let allTransactions = try await transactionRepository.fetchTransactions(userId: userId)
            let currentMonthExpenses = allTransactions.filter {
                $0.type == .expense && calendar.isDate($0.date, equalTo: now, toGranularity: .month)
            }
            
            // Har expense category ke liye spent amount calculate karo aur budget se match karo
            budgetItems = expenseCategories.map { category in
                let spent = currentMonthExpenses
                    .filter { $0.categoryId == category.id }
                    .reduce(0) { $0 + $1.amount }
                
                let budget = budgets.first { $0.categoryId == category.id }
                
                return BudgetProgress(
                    category: category,
                    budget: budget,
                    spent: spent
                )
            }
            
        } catch {
            errorMessage = "Failed to load budgets"
        }
        
        isLoading = false
    }
    
    // MARK: - Set/Update Budget Limit
    func setBudgetLimit(for category: Category, limit: Double) async -> Bool {
        guard let userId = userId else { return false }
        
        guard limit > 0 else {
            errorMessage = "Budget limit must be greater than zero"
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // Agar pehle se budget hai to usi ID ko reuse karo (overwrite ho jayega), nahi to naya ID banao
        let existingId = budgetItems.first { $0.category.id == category.id }?.budget?.id
        
        let newBudget = Budget(
            id: existingId ?? UUID().uuidString,
            categoryId: category.id,
            categoryName: category.name,
            categoryIcon: category.iconName,
            categoryColorHex: category.colorHex,
            monthlyLimit: limit,
            month: currentMonth,
            year: currentYear,
            notifiedThresholds: []
        )
        
        do {
            try await budgetRepository.setBudget(userId: userId, budget: newBudget)
            toastMessage = "Budget Updated Successfully! ✅"
            await loadBudgets()
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                toastMessage = nil
            }
            return true
        } catch {
            errorMessage = "Failed to set budget"
            return false
        }
    }
}

// MARK: - Helper Struct - Category + Budget + Spent combined
struct BudgetProgress: Identifiable {
    var id: String { category.id }
    let category: Category
    let budget: Budget?
    let spent: Double
    
    var limit: Double {
        budget?.monthlyLimit ?? 0
    }
    
    var percentUsed: Double {
        guard limit > 0 else { return 0 }
        return min(spent / limit, 1.0)
    }
    
    var statusColor: String {
        let percent = percentUsed * 100
        if percent >= 100 { return "red" }
        if percent >= 75 { return "yellow" }
        return "green"
    }
    
    var hasBudgetSet: Bool {
        budget != nil
    }
}
