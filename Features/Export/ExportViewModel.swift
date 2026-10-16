import Foundation

@MainActor
class ExportViewModel: ObservableObject {
    
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String? = nil
    @Published var generatedFileURL: URL? = nil
    @Published var exportedCount: Int = 0
    
    private let transactionRepository = TransactionRepository()
    private var userId: String?
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    // MARK: - Generate CSV File
    func generateCSV() async {
        guard let userId = userId else { return }
        errorMessage = nil
        generatedFileURL = nil
        isGenerating = true
        
        // Sanity check - start date end date se pehle honi chahiye
        let validStart = min(startDate, endDate)
        let validEnd = max(startDate, endDate)
        
        do {
            let allTransactions = try await transactionRepository.fetchTransactions(userId: userId)
            
            // Selected date range ke andar filter karo (end date ka poora din include karne ke liye endOfDay use kiya)
            let calendar = Calendar.current
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: validEnd) ?? validEnd
            
            let filteredTransactions = allTransactions.filter {
                $0.date >= validStart && $0.date <= endOfDay
            }
            
            guard !filteredTransactions.isEmpty else {
                errorMessage = "No transactions found in the selected date range"
                isGenerating = false
                return
            }
            
            let csvString = buildCSVString(from: filteredTransactions)
            let fileURL = try writeToTempFile(csvString)
            
            generatedFileURL = fileURL
            exportedCount = filteredTransactions.count
            
        } catch {
            errorMessage = "Failed to generate export file"
        }
        
        isGenerating = false
    }
    
    // MARK: - Build CSV String
    private func buildCSVString(from transactions: [Transaction]) -> String {
        var csv = "Date,Type,Category,Amount,Note\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        // Sabse purani transaction pehle aaye, CSV me chronological order acha lagta hai
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
        
        for txn in sortedTransactions {
            let dateStr = dateFormatter.string(from: txn.date)
            let typeStr = txn.type == .income ? "Income" : "Expense"
            let categoryStr = escapeCSVField(txn.categoryName)
            let amountStr = String(format: "%.2f", txn.amount)
            let noteStr = escapeCSVField(txn.note ?? "")
            
            csv += "\(dateStr),\(typeStr),\(categoryStr),\(amountStr),\(noteStr)\n"
        }
        
        return csv
    }
    
    // Agar note ya category me comma, quote, ya newline ho to CSV format sahi rahe iske liye escape karna
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    // MARK: - Write CSV to Temporary File
    private func writeToTempFile(_ content: String) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMyyyy_HHmmss"
        let fileName = "FinanceTracker_Export_\(dateFormatter.string(from: Date())).csv"
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    func resetExport() {
        generatedFileURL = nil
        exportedCount = 0
        errorMessage = nil
    }
}
