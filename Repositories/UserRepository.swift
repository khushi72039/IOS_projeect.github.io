import Foundation
import FirebaseFirestore

class UserRepository {
    
    private let db = Firestore.firestore()
    
    func createUser(_ user: User) async throws {
        var data: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "currencyCode": user.currencyCode,
            "createdAt": Timestamp(date: user.createdAt),
            "savingsGoalPercent": user.savingsGoalPercent,
            "dailySpendingLimit": user.dailySpendingLimit
        ]
        if let imageBase64 = user.profileImageBase64 {
            data["profileImageBase64"] = imageBase64
        }
        try await db.collection("users").document(user.id).setData(data)
    }
    
    func fetchUser(userId: String) async throws -> User? {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data() else { return nil }
        
        let name = data["name"] as? String ?? ""
        let email = data["email"] as? String ?? ""
        let currencyCode = data["currencyCode"] as? String ?? "INR"
        let timestamp = data["createdAt"] as? Timestamp
        let createdAt = timestamp?.dateValue() ?? Date()
        let savingsGoalPercent = data["savingsGoalPercent"] as? Double ?? 20
        let profileImageBase64 = data["profileImageBase64"] as? String
        let dailySpendingLimit = data["dailySpendingLimit"] as? Double ?? 500
        
        return User(id: userId, name: name, email: email, currencyCode: currencyCode, createdAt: createdAt, savingsGoalPercent: savingsGoalPercent, profileImageBase64: profileImageBase64, dailySpendingLimit: dailySpendingLimit)
    }
    
    func updateUser(_ user: User) async throws {
        try await createUser(user)
    }
}
