//
//  ChartsViewModel.swift
//  Finace_tracker_khushi
//
//  Created by Mobile5 on 22/07/26.
//

import Foundation

@MainActor
class ChartsViewModel: ObservableObject {
    
    @Published var monthlyTotals: [MonthlyTotal] = []
    @Published var categoryBreakdown: [CategorySlice] = []
    @Published var selectedMonthOffset: Int = 0
    @Published var isLoading: Bool = false
    
    private let transactionRepository = TransactionRepository()
    private var allTransactions: [Transaction] = []
    private var userId: String?
    
    
    var availableMonths: [(offset: Int, label: String)] {
        (0..<6).map { offset in
            let date = Calendar.current.date(byAdding: .month, value: -offset, to: Date()) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return (offset, formatter.string(from: date))
        }
    }
    
    func setUserId(_ id: String) {
        self.userId = id
    }
    
    // MARK: - Load All Data
    func loadChartsData() async {
        guard let userId = userId else { return }
        isLoading = true
        
        do {
            allTransactions = try await transactionRepository.fetchTransactions(userId: userId)
            calculateMonthlyTotals()
            calculateCategoryBreakdown()
        } catch {
            print("Error loading charts data: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Bar Chart Data (last 6 months income vs expense)
    private func calculateMonthlyTotals() {
        let calendar = Calendar.current
        var results: [MonthlyTotal] = []
        
        for offset in stride(from: 5, through: 0, by: -1) {
            guard let targetDate = calendar.date(byAdding: .month, value: -offset, to: Date()) else { continue }
            
            let monthTransactions = allTransactions.filter {
                calendar.isDate($0.date, equalTo: targetDate, toGranularity: .month)
            }
            
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            results.append(MonthlyTotal(monthLabel: formatter.string(from: targetDate), income: income, expense: expense))
        }
        
        monthlyTotals = results
    }
    
    // MARK: - Donut Chart Data (selected month category breakdown)
    func calculateCategoryBreakdown() {
        let calendar = Calendar.current
        guard let targetDate = calendar.date(byAdding: .month, value: -selectedMonthOffset, to: Date()) else { return }
        
        let monthExpenses = allTransactions.filter {
            $0.type == .expense && calendar.isDate($0.date, equalTo: targetDate, toGranularity: .month)
        }
        
        let grouped = Dictionary(grouping: monthExpenses) { $0.categoryId }
        let total = monthExpenses.reduce(0) { $0 + $1.amount }
        
        guard total > 0 else {
            categoryBreakdown = []
            return
        }
        
        categoryBreakdown = grouped.compactMap { (_, txns) -> CategorySlice? in
            guard let first = txns.first else { return nil }
            let amount = txns.reduce(0) { $0 + $1.amount }
            return CategorySlice(
                name: first.categoryName,
                amount: amount,
                percentage: amount / total,
                colorHex: first.categoryColorHex
            )
        }
        .sorted { $0.amount > $1.amount }
    }
    
    func onMonthChanged() {
        calculateCategoryBreakdown()
    }
}

// MARK: - Chart Data Structs
struct MonthlyTotal: Identifiable {
    let id = UUID()
    let monthLabel: String
    let income: Double
    let expense: Double
}

struct CategorySlice: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let percentage: Double
    let colorHex: String
}
