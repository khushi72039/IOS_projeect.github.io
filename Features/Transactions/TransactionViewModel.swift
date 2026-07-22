import Foundation

@MainActor
class TransactionViewModel: ObservableObject {
    
    @Published var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var toastMessage: String? = nil
    
    // Add Transaction form fields
    @Published var amountText: String = ""
    @Published var selectedType: CategoryType = .expense
    @Published var selectedCategory: Category? = nil
    @Published var selectedDate: Date = Date()
    @Published var note: String = ""
    
    private let repository = TransactionRepository()
    private var userId: String?
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    // MARK: - Fetch
    func fetchTransactions() async {
        guard let userId = userId else { return }
        isLoading = true
        do {
            transactions = try await repository.fetchTransactions(userId: userId)
        } catch {
            errorMessage = "Failed to load transactions"
        }
        isLoading = false
    }
    
    // MARK: - Computed Totals (Dashboard ke liye kaam aayenge baad me)
    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Grouped by Date (List screen ke liye)
    var groupedTransactions: [(date: String, items: [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { txn -> String in
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
    
    // MARK: - Add Transaction
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
        
        let newTransaction = Transaction(
            id: UUID().uuidString,
            amount: amount,
            type: selectedType,
            categoryId: category.id,
            categoryName: category.name,
            categoryIcon: category.iconName,
            categoryColorHex: category.colorHex,
            date: selectedDate,
            note: note.isEmpty ? nil : note,
            updatedAt: Date()
        )
        
        do {
            try await repository.addTransaction(userId: userId, transaction: newTransaction)
            transactions.insert(newTransaction, at: 0)
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
    
    // MARK: - Delete Transaction
    func deleteTransaction(_ transaction: Transaction) async {
        guard let userId = userId else { return }
        do {
            try await repository.deleteTransaction(userId: userId, transactionId: transaction.id)
            transactions.removeAll { $0.id == transaction.id }
        } catch {
            errorMessage = "Failed to delete transaction"
        }
    }
    
    private func resetForm() {
        amountText = ""
        selectedCategory = nil
        selectedDate = Date()
        note = ""
    }
}
