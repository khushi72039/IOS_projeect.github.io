import Foundation
import FirebaseFirestore
import FirebaseStorage

class TransactionRepository {
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private func transactionsCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("transactions")
    }
    
    func addTransaction(userId: String, transaction: Transaction) async throws {
        var data: [String: Any] = [
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
        if let receiptURL = transaction.receiptImageURL {
            data["receiptImageURL"] = receiptURL
        }
        try await transactionsCollection(userId: userId).document(transaction.id).setData(data)
    }
    
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
            let receiptImageURL = data["receiptImageURL"] as? String
            
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
                receiptImageURL: receiptImageURL,
                updatedAt: updatedTimestamp.dateValue()
            )
        }
    }
    
    func updateTransaction(userId: String, transaction: Transaction) async throws {
        try await addTransaction(userId: userId, transaction: transaction)
    }
    
    func deleteTransaction(userId: String, transactionId: String) async throws {
        try await transactionsCollection(userId: userId).document(transactionId).delete()
    }
    
    // MARK: - Receipt Image Upload to Firebase Storage
    func uploadReceiptImage(userId: String, transactionId: String, imageData: Data) async throws -> String {
        let storageRef = storage.reference().child("users/\(userId)/receipts/\(transactionId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    // MARK: - Delete Receipt Image
    func deleteReceiptImage(userId: String, transactionId: String) async throws {
        let storageRef = storage.reference().child("users/\(userId)/receipts/\(transactionId).jpg")
        try? await storageRef.delete()
    }
}
