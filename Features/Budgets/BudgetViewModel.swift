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
    
    // Ek reasonable maximum budget limit (10 crore)
    static let maxBudgetLimit: Double = 99_999_999
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    func loadBudgets() async {
        guard let userId = userId else { return }
        isLoading = true
        
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        do {
            let categories = try await categoryRepository.fetchCategories(userId: userId)
            let expenseCategories = categories.filter { $0.type == .expense }
            
            let budgets = try await budgetRepository.fetchBudgets(userId: userId, month: currentMonth, year: currentYear)
            
            let allTransactions = try await transactionRepository.fetchTransactions(userId: userId)
            let currentMonthExpenses = allTransactions.filter {
                $0.type == .expense && calendar.isDate($0.date, equalTo: now, toGranularity: .month)
            }
            
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
    
    // MARK: - Set/Update Budget Limit (ab maximum limit check ke saath)
    func setBudgetLimit(for category: Category, limit: Double) async -> Bool {
        guard let userId = userId else { return false }
        
        guard limit > 0 else {
            errorMessage = "Budget limit must be greater than zero"
            return false
        }
        
        guard limit <= BudgetViewModel.maxBudgetLimit else {
            errorMessage = "Budget limit cannot exceed ₹9,99,99,999"
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
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
