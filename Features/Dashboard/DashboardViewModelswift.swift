import Foundation
import UIKit

@MainActor
class DashboardViewModel: ObservableObject {
    
    @Published var totalIncome: Double = 0
    @Published var totalExpense: Double = 0
    @Published var userName: String = "User"
    @Published var userProfileImage: UIImage? = nil
    @Published var isLoading: Bool = false
    
    @Published var topCategories: [CategorySpend] = []
    @Published var recentTransactions: [RecentTransaction] = []
    
    @Published var isBudgetAlertVisible: Bool = false
    @Published var budgetAlertMessage: String = ""
    
    @Published var selectedMonthOption: MonthOption = MonthSelectorView.currentMonthOption
    @Published var monthOptions: [MonthOption] = [MonthSelectorView.currentMonthOption]
    
    private let transactionRepository = TransactionRepository()
    private var userId: String?
    private var allTransactionsCache: [Transaction] = []
    
    var netBalance: Double {
        totalIncome - totalExpense
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    func setUserName(_ name: String) {
        self.userName = name.isEmpty ? "User" : name
    }
    
    func setUserProfileImage(_ base64: String?) {
        if let base64 = base64 {
            userProfileImage = ImageHelper.imageFromBase64(base64)
        }
    }
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    func loadDashboardData() async {
        guard let userId = userId else { return }
        isLoading = true
        
        do {
            let allTransactions = try await transactionRepository.fetchTransactions(userId: userId)
            allTransactionsCache = allTransactions
            
            // Month dropdown ko user ki asli transaction history ke hisaab se update karo
            monthOptions = MonthSelectorView.generateOptions(from: allTransactions)
            
            let calendar = Calendar.current
            
            let relevantTransactions: [Transaction]
            if let monthDate = selectedMonthOption.date {
                relevantTransactions = allTransactions.filter { calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month) }
            } else {
                relevantTransactions = allTransactions
            }
            
            totalIncome = relevantTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            totalExpense = relevantTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            let expenseTransactions = relevantTransactions.filter { $0.type == .expense }
            let grouped = Dictionary(grouping: expenseTransactions) { $0.categoryId }
            
            let categorySpends = grouped.compactMap { (_, txns) -> CategorySpend? in
                guard let first = txns.first else { return nil }
                let total = txns.reduce(0) { $0 + $1.amount }
                return CategorySpend(name: first.categoryName, iconName: first.categoryIcon, amount: total, colorHex: first.categoryColorHex)
            }
            topCategories = categorySpends.sorted { $0.amount > $1.amount }.prefix(3).map { $0 }
            
            recentTransactions = relevantTransactions.prefix(5).map { txn in
                RecentTransaction(
                    title: txn.categoryName, category: txn.categoryName,
                    amount: txn.type == .income ? txn.amount : -txn.amount,
                    date: formatRelativeDate(txn.date), iconName: txn.categoryIcon, colorHex: txn.categoryColorHex
                )
            }
            
            let currentMonthTransactions = allTransactions.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            await checkBudgetAlerts(userId: userId, currentMonthTransactions: currentMonthTransactions)
            
        } catch {
            print("Error loading dashboard data: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
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
                    return
                }
            }
            isBudgetAlertVisible = false
        } catch {
            isBudgetAlertVisible = false
        }
    }
}

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
    let amount: Double
    let date: String
    let iconName: String
    let colorHex: String
}
