import Foundation

@MainActor
class CategoryViewModel: ObservableObject {
    
    @Published var categories: [Category] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // New category form fields
    @Published var newCategoryName: String = ""
    @Published var newCategoryIcon: String = "tag.fill"
    @Published var newCategoryColorHex: String = "54A0FF"
    @Published var newCategoryType: CategoryType = .expense
    
    private let repository = CategoryRepository()
    private var userId: String?
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    // Saari categories fetch karne ke liye
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
    
    // Income aur Expense categories ko alag-alag dikhane ke liye computed properties
    var incomeCategories: [Category] {
        categories.filter { $0.type == .income }
    }
    
    var expenseCategories: [Category] {
        categories.filter { $0.type == .expense }
    }
    
    // Naya custom category add karne ke liye
    func addCategory() async -> Bool {
        guard let userId = userId else { return false }
        errorMessage = nil
        
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Category name cannot be empty"
            return false
        }
        
        // Duplicate name check (case-insensitive)
        if categories.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            errorMessage = "This category already exists"
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
            resetForm()
            return true
        } catch {
            errorMessage = "Failed to add category"
            return false
        }
    }
    
    // Category delete karne ke liye - sirf custom categories delete ho sakti hain
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
