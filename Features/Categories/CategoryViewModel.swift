import Foundation

@MainActor
class CategoryViewModel: ObservableObject {
    
    @Published var categories: [Category] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var newCategoryName: String = ""
    @Published var newCategoryIcon: String = "tag.fill"
    @Published var newCategoryColorHex: String = "54A0FF"
    @Published var newCategoryType: CategoryType = .expense
    
    private let repository = CategoryRepository()
    private var userId: String?
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    func fetchCategories() async {
        guard let userId = userId else { return }
        isLoading = true
        do {
            categories = try await repository.fetchCategories(userId: userId)
        } catch {
            errorMessage = "Failed to load categories"
        }
        isLoading = false
    }
    
    var incomeCategories: [Category] {
        categories.filter { $0.type == .income }
    }
    
    var expenseCategories: [Category] {
        categories.filter { $0.type == .expense }
    }
    
    // MARK: - Add Category (naye custom expense category ke liye default budget bhi banata hai)
    func addCategory() async -> Bool {
        guard let userId = userId else { return false }
        errorMessage = nil
        
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Category name cannot be empty"
            return false
        }
        
        if categories.contains(where: { $0.name.lowercased() == trimmedName.lowercased() && $0.type == newCategoryType }) {
            errorMessage = "This category already exists in \(newCategoryType == .income ? "Income" : "Expense")"
            return false
        }
        
        let newCategory = Category(
            id: UUID().uuidString,
            name: trimmedName,
            iconName: newCategoryIcon,
            colorHex: newCategoryColorHex,
            type: newCategoryType,
            isDefault: false
        )
        
        do {
            try await repository.addCategory(userId: userId, category: newCategory)
            categories.append(newCategory)
            
            // Naya expense category ke liye default budget bhi bana do
            if newCategory.type == .expense {
                let budgetRepository = BudgetRepository()
                let calendar = Calendar.current
                let now = Date()
                let defaultBudget = Budget(
                    id: UUID().uuidString, categoryId: newCategory.id, categoryName: newCategory.name,
                    categoryIcon: newCategory.iconName, categoryColorHex: newCategory.colorHex,
                    monthlyLimit: 1000, month: calendar.component(.month, from: now),
                    year: calendar.component(.year, from: now), notifiedThresholds: []
                )
                try? await budgetRepository.setBudget(userId: userId, budget: defaultBudget)
            }
            
            resetForm()
            return true
        } catch {
            errorMessage = "Failed to add category"
            return false
        }
    }
    
    func deleteCategory(_ category: Category) async {
        guard let userId = userId else { return }
        guard !category.isDefault else {
            errorMessage = "Default categories cannot be deleted"
            return
        }
        
        do {
            try await repository.deleteCategory(userId: userId, categoryId: category.id)
            categories.removeAll { $0.id == category.id }
        } catch {
            errorMessage = "Failed to delete category"
        }
    }
    
    private func resetForm() {
        newCategoryName = ""
        newCategoryIcon = "tag.fill"
        newCategoryColorHex = "54A0FF"
        newCategoryType = .expense
    }
}
