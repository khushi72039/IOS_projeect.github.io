import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    
    @Published var totalIncome: Double = 0
    @Published var totalExpense: Double = 0
    @Published var userName: String = "User"
    @Published var isLoading: Bool = false
    
    @Published var topCategories: [CategorySpend] = []
    @Published var recentTransactions: [RecentTransaction] = []
    
    // Budget Model bante hi isko wapas enable karenge
    @Published var isBudgetAlertVisible: Bool = false
    @Published var budgetAlertMessage: String = ""
    
    private let transactionRepository = TransactionRepository()
    private var userId: String?
    
    var netBalance: Double {
        totalIncome - totalExpense
    }
    
    func setUserName(_ name: String) {
        self.userName = name.isEmpty ? "User" : name
    }
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    // MARK: - Load Dashboard Data (Firestore se real transactions fetch karke calculate karta hai)
    func loadDashboardData() async {
        guard let userId = userId else { return }
        isLoading = true
        
        do {
            let allTransactions = try await transactionRepository.fetchTransactions(userId: userId)
            
            // Sirf current month ki transactions filter karo
            let calendar = Calendar.current
            let now = Date()
            let currentMonthTransactions = allTransactions.filter {
                calendar.isDate($0.date, equalTo: now, toGranularity: .month)
            }
            
            // Totals calculate karo
            totalIncome = currentMonthTransactions
                .filter { $0.type == .income }
                .reduce(0) { $0 + $1.amount }
            
            totalExpense = currentMonthTransactions
                .filter { $0.type == .expense }
                .reduce(0) { $0 + $1.amount }
            
            // Top spending categories calculate karo (expense wali transactions ko category ke hisaab se group karke)
            let expenseTransactions = currentMonthTransactions.filter { $0.type == .expense }
            let grouped = Dictionary(grouping: expenseTransactions) { $0.categoryId }
            
            let categorySpends = grouped.compactMap { (categoryId, txns) -> CategorySpend? in
                guard let first = txns.first else { return nil }
                let total = txns.reduce(0) { $0 + $1.amount }
                return CategorySpend(
                    name: first.categoryName,
                    iconName: first.categoryIcon,
                    amount: total,
                    colorHex: first.categoryColorHex
                )
            }
            
            topCategories = categorySpends
                .sorted { $0.amount > $1.amount }
                .prefix(3)
                .map { $0 }
            
            // Recent 5 transactions (sabse naye)
            recentTransactions = allTransactions
                .prefix(5)
                .map { txn in
                    RecentTransaction(
                        title: txn.categoryName,
                        category: txn.categoryName,
                        amount: txn.type == .income ? txn.amount : -txn.amount,
                        date: formatRelativeDate(txn.date),
                        iconName: txn.categoryIcon,
                        colorHex: txn.categoryColorHex
                    )
                }
            
            // Budget alert check karna
                        await checkBudgetAlerts(userId: userId, currentMonthTransactions: currentMonthTransactions)
                        
                    } catch {
                        print("Error loading dashboard data: \(error.localizedDescription)")
                    }
                    
                    isLoading = false
                }
                
                // MARK: - Budget Alert Check
                private func checkBudgetAlerts(userId: String, currentMonthTransactions: [Transaction]) async {
                    let budgetRepository = BudgetRepository()
                    let calendar = Calendar.current
                    let now = Date()
                    let month = calendar.component(.month, from: now)
                    let year = calendar.component(.year, from: now)
                    
                    do {
                        let budgets = try await budgetRepository.fetchBudgets(userId: userId, month: month, year: year)
                        
                        for budget in budgets {
                            let spent = currentMonthTransactions
                                .filter { $0.categoryId == budget.categoryId && $0.type == .expense }
                                .reduce(0) { $0 + $1.amount }
                            
                            let percent = budget.monthlyLimit > 0 ? (spent / budget.monthlyLimit) * 100 : 0
                            
                            if percent >= 90 {
                                isBudgetAlertVisible = true
                                budgetAlertMessage = "\(budget.categoryName) has reached \(Int(percent))% of its budget"
                                return // Sirf ek alert dikhate hain sabse pehle mile hue budget ka
                            }
                        }
                        
                        isBudgetAlertVisible = false
                    } catch {
                        isBudgetAlertVisible = false
                    }
                }
    
    // Date ko "Today", "Yesterday", ya normal date format me dikhane ke liye
    private func formatRelativeDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Dashboard Display Structs
struct CategorySpend: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let amount: Double
    let colorHex: String
}

struct RecentTransaction: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let amount: Double   // negative = expense, positive = income
    let date: String
    let iconName: String
    let colorHex: String
}
