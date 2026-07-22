import Foundation
import FirebaseFirestore

class TransactionRepository {
    
    private let db = Firestore.firestore()
    
    private func transactionsCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("transactions")
    }
    
    // Nayi transaction add karne ke liye
    func addTransaction(userId: String, transaction: Transaction) async throws {
        let data: [String: Any] = [
            "id": transaction.id,
            "amount": transaction.amount,
            "type": transaction.type.rawValue,
            "categoryId": transaction.categoryId,
            "categoryName": transaction.categoryName,
            "categoryIcon": transaction.categoryIcon,
            "categoryColorHex": transaction.categoryColorHex,
            "date": Timestamp(date: transaction.date),
            "note": transaction.note ?? "",
            "updatedAt": Timestamp(date: transaction.updatedAt)
        ]
        try await transactionsCollection(userId: userId).document(transaction.id).setData(data)
    }
    
    // Saari transactions fetch karne ke liye (date ke hisaab se newest pehle)
    func fetchTransactions(userId: String) async throws -> [Transaction] {
        let snapshot = try await transactionsCollection(userId: userId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let amount = data["amount"] as? Double,
                  let typeRaw = data["type"] as? String,
                  let type = CategoryType(rawValue: typeRaw),
                  let categoryId = data["categoryId"] as? String,
                  let categoryName = data["categoryName"] as? String,
                  let categoryIcon = data["categoryIcon"] as? String,
                  let categoryColorHex = data["categoryColorHex"] as? String,
                  let dateTimestamp = data["date"] as? Timestamp,
                  let updatedTimestamp = data["updatedAt"] as? Timestamp else {
                return nil
            }
            
            let note = data["note"] as? String
            
            return Transaction(
                id: doc.documentID,
                amount: amount,
                type: type,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                categoryColorHex: categoryColorHex,
                date: dateTimestamp.dateValue(),
                note: note?.isEmpty == true ? nil : note,
                updatedAt: updatedTimestamp.dateValue()
            )
        }
    }
    
    // Transaction update karne ke liye (Edit ke liye)
    func updateTransaction(userId: String, transaction: Transaction) async throws {
        try await addTransaction(userId: userId, transaction: transaction) // setData overwrite kar deta hai
    }
    
    // Transaction delete karne ke liye
    func deleteTransaction(userId: String, transactionId: String) async throws {
        try await transactionsCollection(userId: userId).document(transactionId).delete()
    }
}
