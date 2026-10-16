import Foundation

@MainActor
class InsightsViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var toastMessage: String? = nil
    
    // Spending Habits
    @Published var topCategoryName: String = "N/A"
    @Published var averageTransactionSize: Double = 0
    @Published var mostSpendingDay: String = "N/A"
    
    // Budget Health
    @Published var categoriesNearLimit: Int = 0
    @Published var totalBudgetedCategories: Int = 0
    @Published var budgetAdherencePercent: Double = 100
    
    // Savings Analysis
    @Published var savingsRate: Double = 0
    @Published var savingsGoalPercent: Double = 20
    
    // Monthly Comparison
    @Published var categoryComparisons: [CategoryComparison] = []
    
    // Financial Score
    @Published var financialScore: Int = 0
    @Published var scoreLabel: String = "Needs Attention"
    
    // Smart Suggestions
    @Published var suggestions: [String] = []
    
    private let transactionRepository = TransactionRepository()
    private let budgetRepository = BudgetRepository()
    private let userRepository = UserRepository()
    private var userId: String?
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    // MARK: - Main Load Function
    func loadInsights() async {
        guard let userId = userId else { return }
        isLoading = true
        
        do {
            let allTransactions = try await transactionRepository.fetchTransactions(userId: userId)
            let calendar = Calendar.current
            let now = Date()
            
            let currentMonthTxns = allTransactions.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let lastMonthTxns = allTransactions.filter { calendar.isDate($0.date, equalTo: lastMonthDate, toGranularity: .month) }
            
            // Savings goal fetch karo user profile se
            if let user = try await userRepository.fetchUser(userId: userId) {
                savingsGoalPercent = user.savingsGoalPercent
            }
            
            calculateSpendingHabits(currentMonthTxns)
            await calculateBudgetHealth(userId: userId, currentMonthTxns: currentMonthTxns)
            calculateSavingsAnalysis(currentMonthTxns)
            calculateMonthlyComparison(current: currentMonthTxns, last: lastMonthTxns)
            calculateFinancialScore()
            generateSmartSuggestions(currentMonthTxns: currentMonthTxns, lastMonthTxns: lastMonthTxns)
            
        } catch {
            print("Error loading insights: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - 1. Spending Habits
    private func calculateSpendingHabits(_ transactions: [Transaction]) {
        let expenses = transactions.filter { $0.type == .expense }
        
        guard !expenses.isEmpty else {
            topCategoryName = "N/A"
            averageTransactionSize = 0
            mostSpendingDay = "N/A"
            return
        }
        
        // Top category
        let grouped = Dictionary(grouping: expenses) { $0.categoryName }
        let topCategory = grouped.max { a, b in
            a.value.reduce(0) { $0 + $1.amount } < b.value.reduce(0) { $0 + $1.amount }
        }
        topCategoryName = topCategory?.key ?? "N/A"
        
        // Average transaction size
        averageTransactionSize = expenses.reduce(0) { $0 + $1.amount } / Double(expenses.count)
        
        // Sabse zyada kharch wala din
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let groupedByDay = Dictionary(grouping: expenses) { dayFormatter.string(from: $0.date) }
        let topDay = groupedByDay.max { a, b in
            a.value.reduce(0) { $0 + $1.amount } < b.value.reduce(0) { $0 + $1.amount }
        }
        mostSpendingDay = topDay?.key ?? "N/A"
    }
    
    // MARK: - 2. Budget Health
    private func calculateBudgetHealth(userId: String, currentMonthTxns: [Transaction]) async {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        do {
            let budgets = try await budgetRepository.fetchBudgets(userId: userId, month: month, year: year)
            totalBudgetedCategories = budgets.count
            
            guard !budgets.isEmpty else {
                categoriesNearLimit = 0
                budgetAdherencePercent = 100
                return
            }
            
            var nearLimitCount = 0
            var withinLimitCount = 0
            
            for budget in budgets {
                let spent = currentMonthTxns
                    .filter { $0.categoryId == budget.categoryId && $0.type == .expense }
                    .reduce(0) { $0 + $1.amount }
                
                let percent = budget.monthlyLimit > 0 ? (spent / budget.monthlyLimit) * 100 : 0
                
                if percent >= 75 { nearLimitCount += 1 }
                if percent <= 100 { withinLimitCount += 1 }
            }
            
            categoriesNearLimit = nearLimitCount
            budgetAdherencePercent = (Double(withinLimitCount) / Double(budgets.count)) * 100
            
        } catch {
            categoriesNearLimit = 0
            budgetAdherencePercent = 100
        }
    }
    
    // MARK: - 3. Savings Analysis
    private func calculateSavingsAnalysis(_ transactions: [Transaction]) {
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        
        guard income > 0 else {
            savingsRate = 0
            return
        }
        
        savingsRate = ((income - expense) / income) * 100
    }
    
    // MARK: - 4. Monthly Comparison
    private func calculateMonthlyComparison(current: [Transaction], last: [Transaction]) {
        let currentExpenses = current.filter { $0.type == .expense }
        let lastExpenses = last.filter { $0.type == .expense }
        
        let currentGrouped = Dictionary(grouping: currentExpenses) { $0.categoryId }
        let lastGrouped = Dictionary(grouping: lastExpenses) { $0.categoryId }
        
        var results: [CategoryComparison] = []
        let allCategoryIds = Set(currentGrouped.keys).union(lastGrouped.keys)
        
        for categoryId in allCategoryIds {
            let currentAmount = currentGrouped[categoryId]?.reduce(0) { $0 + $1.amount } ?? 0
            let lastAmount = lastGrouped[categoryId]?.reduce(0) { $0 + $1.amount } ?? 0
            let name = currentGrouped[categoryId]?.first?.categoryName ?? lastGrouped[categoryId]?.first?.categoryName ?? "Unknown"
            
            guard currentAmount > 0 || lastAmount > 0 else { continue }
            
            let percentChange: Double
            if lastAmount > 0 {
                percentChange = ((currentAmount - lastAmount) / lastAmount) * 100
            } else {
                percentChange = 100
            }
            
            results.append(CategoryComparison(categoryName: name, currentAmount: currentAmount, lastAmount: lastAmount, percentChange: percentChange))
        }
        
        categoryComparisons = results.sorted { abs($0.percentChange) > abs($1.percentChange) }
    }
    
    // MARK: - 5. Financial Score
    private func calculateFinancialScore() {
        // Budget Adherence (50% weight)
        let budgetScore = budgetAdherencePercent
        
        // Savings vs Goal (30% weight)
        let savingsScore: Double
        if savingsGoalPercent > 0 {
            savingsScore = min((savingsRate / savingsGoalPercent) * 100, 100)
        } else {
            savingsScore = savingsRate >= 0 ? 100 : 0
        }
        let clampedSavingsScore = max(savingsScore, 0)
        
        // Bill Coverage (20% weight) - Recurring feature abhi nahi bana, isliye neutral 100 rakha hai
        let billCoverageScore: Double = 100
        
        let totalScore = (budgetScore * 0.5) + (clampedSavingsScore * 0.3) + (billCoverageScore * 0.2)
        financialScore = Int(totalScore.rounded())
        
        if financialScore >= 75 {
            scoreLabel = "Good"
        } else if financialScore >= 50 {
            scoreLabel = "Needs Attention"
        } else {
            scoreLabel = "Poor"
        }
    }
    
    // MARK: - 6. Smart Suggestions (Rule-based)
    private func generateSmartSuggestions(currentMonthTxns: [Transaction], lastMonthTxns: [Transaction]) {
        var tips: [String] = []
        
        // Rule 1: Category spending increase
        if let topIncrease = categoryComparisons.first(where: { $0.percentChange > 20 }) {
            tips.append("\(topIncrease.categoryName) spending is \(Int(topIncrease.percentChange))% higher than last month")
        }
        
        // Rule 2: Savings goal tracking
        if savingsRate >= savingsGoalPercent {
            tips.append("You're on track to hit your savings goal this month")
        } else if savingsRate > 0 {
            tips.append("You're saving, but below your \(Int(savingsGoalPercent))% goal. Consider reducing discretionary spending")
        } else {
            tips.append("Your expenses exceeded your income this month. Review your spending closely")
        }
        
        // Rule 3: Budget alert
        if categoriesNearLimit > 0 {
            tips.append("\(categoriesNearLimit) categor\(categoriesNearLimit == 1 ? "y is" : "ies are") close to or over budget this month")
        }
        
        // Rule 4: Average transaction size
        if averageTransactionSize > 0 {
            tips.append("Your average transaction size this month is ₹\(Int(averageTransactionSize))")
        }
        
        // Rule 5: Most spending day
        if mostSpendingDay != "N/A" {
            tips.append("You tend to spend the most on \(mostSpendingDay)s")
        }
        
        suggestions = tips
    }
    
    // MARK: - Update Savings Goal
    func updateSavingsGoal(_ newGoal: Double) async {
        guard let userId = userId else { return }
        
        guard newGoal > 0 && newGoal <= 100 else {
            return
        }
        
        do {
            if var user = try await userRepository.fetchUser(userId: userId) {
                user.savingsGoalPercent = newGoal
                try await userRepository.updateUser(user)
                savingsGoalPercent = newGoal
                calculateFinancialScore()
                toastMessage = "Savings Goal Updated! ✅"
                
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    toastMessage = nil
                }
            }
        } catch {
            print("Error updating savings goal: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Struct
struct CategoryComparison: Identifiable {
    let id = UUID()
    let categoryName: String
    let currentAmount: Double
    let lastAmount: Double
    let percentChange: Double
}
