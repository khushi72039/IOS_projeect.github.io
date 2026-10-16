import Foundation
import FirebaseFirestore

class CategoryRepository {
    
    private let db = Firestore.firestore()
    
    private func categoriesCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("categories")
    }
    
    func addCategory(userId: String, category: Category) async throws {
        let data: [String: Any] = [
            "id": category.id,
            "name": category.name,
            "iconName": category.iconName,
            "colorHex": category.colorHex,
            "type": category.type.rawValue,
            "isDefault": category.isDefault
        ]
        try await categoriesCollection(userId: userId).document(category.id).setData(data)
    }
    
    func fetchCategories(userId: String) async throws -> [Category] {
        let snapshot = try await categoriesCollection(userId: userId).getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let name = data["name"] as? String,
                  let iconName = data["iconName"] as? String,
                  let colorHex = data["colorHex"] as? String,
                  let typeRaw = data["type"] as? String,
                  let type = CategoryType(rawValue: typeRaw),
                  let isDefault = data["isDefault"] as? Bool else {
                return nil
            }
            return Category(id: doc.documentID, name: name, iconName: iconName, colorHex: colorHex, type: type, isDefault: isDefault)
        }
    }
    
    func deleteCategory(userId: String, categoryId: String) async throws {
        try await categoriesCollection(userId: userId).document(categoryId).delete()
    }
    
    // MARK: - Seed Default Categories (naye signup ke waqt) - ab created categories return karta hai
    @discardableResult
    func seedDefaultCategories(userId: String) async throws -> [Category] {
        let defaults: [Category] = [
            Category(id: UUID().uuidString, name: "Food", iconName: "fork.knife", colorHex: "FF9F43", type: .expense, isDefault: true),
            Category(id: UUID().uuidString, name: "Transport", iconName: "car.fill", colorHex: "54A0FF", type: .expense, isDefault: true),
            Category(id: UUID().uuidString, name: "Entertainment", iconName: "popcorn.fill", colorHex: "A55EEA", type: .expense, isDefault: true),
            Category(id: UUID().uuidString, name: "Shopping", iconName: "bag.fill", colorHex: "FD79A8", type: .expense, isDefault: true),
            Category(id: UUID().uuidString, name: "Bills", iconName: "doc.text.fill", colorHex: "778CA3", type: .expense, isDefault: true),
            Category(id: UUID().uuidString, name: "Health", iconName: "cross.case.fill", colorHex: "26DE81", type: .expense, isDefault: true),
            Category(id: UUID().uuidString, name: "Salary", iconName: "banknote.fill", colorHex: "20BF6B", type: .income, isDefault: true),
            Category(id: UUID().uuidString, name: "Other", iconName: "ellipsis.circle.fill", colorHex: "8395A7", type: .expense, isDefault: true)
        ]
        
        for category in defaults {
            try await addCategory(userId: userId, category: category)
        }
        return defaults
    }
}
