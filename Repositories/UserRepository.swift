//
//  UserRepository.swift
//  Finace_tracker_khushi
//
//  Created by Mobile5 on 09/07/26.
//

import Foundation
import FirebaseFirestore

class UserRepository {
    
    private let db = Firestore.firestore()
    
    // Signup ke baad naya User document Firestore me banane ke liye
    func createUser(_ user: User) async throws {
        let data: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "currencyCode": user.currencyCode,
            "createdAt": Timestamp(date: user.createdAt)
        ]
        
        try await db.collection("users").document(user.id).setData(data)
    }
    
    // Login ke baad ya app open hote hi user ka data fetch karne ke liye
    func fetchUser(userId: String) async throws -> User? {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data() else { return nil }
        
        let name = data["name"] as? String ?? ""
        let email = data["email"] as? String ?? ""
        let currencyCode = data["currencyCode"] as? String ?? "INR"
        let timestamp = data["createdAt"] as? Timestamp
        let createdAt = timestamp?.dateValue() ?? Date()
        
        return User(id: userId, name: name, email: email, currencyCode: currencyCode, createdAt: createdAt)
    }
    
    // Currency ya naam update karne ke liye (future me Settings screen me kaam aayega)
    func updateUser(_ user: User) async throws {
        try await createUser(user) // setData overwrite kar deta hai, isliye same function reuse kar sakte hain
    }
}
