import Foundation
import FirebaseFirestore

class RecurringRuleRepository {
    
    private let db = Firestore.firestore()
    
    private func rulesCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("recurringRules")
    }
    
    func addRule(userId: String, rule: RecurringRule) async throws {
        let data: [String: Any] = [
            "id": rule.id,
            "frequency": rule.frequency.rawValue,
            "startDate": Timestamp(date: rule.startDate),
            "lastGeneratedDate": Timestamp(date: rule.lastGeneratedDate),
            "isActive": rule.isActive,
            "amount": rule.amount,
            "type": rule.type.rawValue,
            "categoryId": rule.categoryId,
            "categoryName": rule.categoryName,
            "categoryIcon": rule.categoryIcon,
            "categoryColorHex": rule.categoryColorHex,
            "note": rule.note ?? ""
        ]
        try await rulesCollection(userId: userId).document(rule.id).setData(data)
    }
    
    func fetchAllRules(userId: String) async throws -> [RecurringRule] {
        let snapshot = try await rulesCollection(userId: userId).getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let frequencyRaw = data["frequency"] as? String,
                  let frequency = RecurringFrequency(rawValue: frequencyRaw),
                  let startTimestamp = data["startDate"] as? Timestamp,
                  let lastGenTimestamp = data["lastGeneratedDate"] as? Timestamp,
                  let isActive = data["isActive"] as? Bool,
                  let amount = data["amount"] as? Double,
                  let typeRaw = data["type"] as? String,
                  let type = CategoryType(rawValue: typeRaw),
                  let categoryId = data["categoryId"] as? String,
                  let categoryName = data["categoryName"] as? String,
                  let categoryIcon = data["categoryIcon"] as? String,
                  let categoryColorHex = data["categoryColorHex"] as? String else {
                return nil
            }
            let note = data["note"] as? String
            
            return RecurringRule(
                id: doc.documentID, frequency: frequency, startDate: startTimestamp.dateValue(),
                lastGeneratedDate: lastGenTimestamp.dateValue(), isActive: isActive,
                amount: amount, type: type, categoryId: categoryId, categoryName: categoryName,
                categoryIcon: categoryIcon, categoryColorHex: categoryColorHex,
                note: note?.isEmpty == true ? nil : note
            )
        }
    }
    
    func updateLastGeneratedDate(userId: String, ruleId: String, date: Date) async throws {
        try await rulesCollection(userId: userId).document(ruleId).updateData([
            "lastGeneratedDate": Timestamp(date: date)
        ])
    }
    
    func setActive(userId: String, ruleId: String, isActive: Bool) async throws {
        try await rulesCollection(userId: userId).document(ruleId).updateData([
            "isActive": isActive
        ])
    }
    
    func deleteRule(userId: String, ruleId: String) async throws {
        try await rulesCollection(userId: userId).document(ruleId).delete()
    }
}
