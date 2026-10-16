import Foundation
import UIKit

@MainActor
class TransactionViewModel: ObservableObject {
    
    @Published var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var toastMessage: String? = nil
    
    @Published var searchText: String = ""
    @Published var filterType: CategoryType? = nil
    @Published var filterCategoryId: String? = nil
    @Published var filterStartDate: Date? = nil
    @Published var filterEndDate: Date? = nil
    @Published var isFilterActive: Bool = false
    
    @Published var selectedMonthOption: MonthOption = MonthSelectorView.currentMonthOption
    @Published var monthOptions: [MonthOption] = [MonthSelectorView.currentMonthOption]
    
    @Published var amountText: String = ""
    @Published var selectedType: CategoryType = .expense
    @Published var selectedCategory: Category? = nil
    @Published var selectedDate: Date = Date()
    @Published var note: String = ""
    @Published var selectedReceiptImage: UIImage? = nil
    @Published var isUploadingImage: Bool = false
    
    @Published var isRecurringEnabled: Bool = false
    @Published var recurringFrequency: RecurringFrequency = .monthly
    
    private let repository = TransactionRepository()
    private let recurringRuleRepository = RecurringRuleRepository()
    private var userId: String?
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    func fetchTransactions() async {
        guard let userId = userId else { return }
        isLoading = true
        do {
            transactions = try await repository.fetchTransactions(userId: userId)
            monthOptions = MonthSelectorView.generateOptions(from: transactions)
        } catch {
            errorMessage = "Failed to load transactions"
        }
        isLoading = false
    }
    
    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let hasCustomDateRange = filterStartDate != nil || filterEndDate != nil
        
        return transactions.filter { txn in
            let matchesSearch = searchText.isEmpty ||
                txn.categoryName.localizedCaseInsensitiveContains(searchText) ||
                (txn.note?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesType = filterType == nil || txn.type == filterType
            let matchesCategory = filterCategoryId == nil || txn.categoryId == filterCategoryId
            let matchesStartDate = filterStartDate == nil || txn.date >= filterStartDate!
            let matchesEndDate = filterEndDate == nil || txn.date <= filterEndDate!
            
            let matchesMonth: Bool
            if hasCustomDateRange {
                matchesMonth = true
            } else if let monthDate = selectedMonthOption.date {
                matchesMonth = calendar.isDate(txn.date, equalTo: monthDate, toGranularity: .month)
            } else {
                matchesMonth = true
            }
            
            return matchesSearch && matchesType && matchesCategory && matchesStartDate && matchesEndDate && matchesMonth
        }
    }
    
    var filteredGroupedTransactions: [(date: String, items: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { txn -> String in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: txn.date)
        }
        return grouped.map { (date: $0.key, items: $0.value) }
            .sorted { first, second in
                guard let firstDate = first.items.first?.date,
                      let secondDate = second.items.first?.date else { return false }
                return firstDate > secondDate
            }
    }
    
    func clearFilters() {
        filterType = nil
        filterCategoryId = nil
        filterStartDate = nil
        filterEndDate = nil
        isFilterActive = false
    }
    
    func applyFilters() {
        isFilterActive = (filterType != nil || filterCategoryId != nil || filterStartDate != nil || filterEndDate != nil)
    }
    
    func addTransaction() async -> Bool {
        guard let userId = userId else { return false }
        errorMessage = nil
        
        guard let amount = Double(amountText), amount > 0 else {
            errorMessage = "Please enter a valid amount greater than zero"
            return false
        }
        guard let category = selectedCategory else {
            errorMessage = "Please select a category"
            return false
        }
        guard note.count <= 280 else {
            errorMessage = "Note must be under 280 characters"
            return false
        }
        
        let transactionId = UUID().uuidString
        var receiptURL: String? = nil
        
        if let image = selectedReceiptImage {
            isUploadingImage = true
            if let imageData = image.jpegData(compressionQuality: 0.5) {
                do {
                    receiptURL = try await repository.uploadReceiptImage(userId: userId, transactionId: transactionId, imageData: imageData)
                } catch {
                    errorMessage = "Failed to upload receipt image"
                    isUploadingImage = false
                    return false
                }
            }
            isUploadingImage = false
        }
        
        let newTransaction = Transaction(
            id: transactionId, amount: amount, type: selectedType,
            categoryId: category.id, categoryName: category.name, categoryIcon: category.iconName,
            categoryColorHex: category.colorHex, date: selectedDate,
            note: note.isEmpty ? nil : note, receiptImageURL: receiptURL, updatedAt: Date()
        )
        
        do {
            try await repository.addTransaction(userId: userId, transaction: newTransaction)
            transactions.insert(newTransaction, at: 0)
            monthOptions = MonthSelectorView.generateOptions(from: transactions)
            
            if isRecurringEnabled {
                let rule = RecurringRule(
                    id: UUID().uuidString, frequency: recurringFrequency, startDate: selectedDate,
                    lastGeneratedDate: selectedDate, isActive: true, amount: amount, type: selectedType,
                    categoryId: category.id, categoryName: category.name, categoryIcon: category.iconName,
                    categoryColorHex: category.colorHex, note: note.isEmpty ? nil : note
                )
                try? await recurringRuleRepository.addRule(userId: userId, rule: rule)
            }
            
            if newTransaction.type == .expense {
                Task {
                    await BudgetAlertChecker.shared.checkAndNotify(userId: userId, categoryId: newTransaction.categoryId)
                }
            }
            
            toastMessage = "Transaction Added Successfully! ✅"
            resetForm()
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                toastMessage = nil
            }
            return true
        } catch {
            errorMessage = "Failed to add transaction"
            return false
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async {
        guard let userId = userId else { return }
        do {
            try await repository.deleteTransaction(userId: userId, transactionId: transaction.id)
            if transaction.receiptImageURL != nil {
                try? await repository.deleteReceiptImage(userId: userId, transactionId: transaction.id)
            }
            transactions.removeAll { $0.id == transaction.id }
            monthOptions = MonthSelectorView.generateOptions(from: transactions)
        } catch {
            errorMessage = "Failed to delete transaction"
        }
    }
    
    private func resetForm() {
        amountText = ""
        selectedCategory = nil
        selectedDate = Date()
        note = ""
        selectedReceiptImage = nil
        isRecurringEnabled = false
        recurringFrequency = .monthly
    }
}
