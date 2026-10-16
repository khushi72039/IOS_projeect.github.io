import SwiftUI

struct TransactionFilterView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @StateObject private var categoryViewModel = CategoryViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempType: CategoryType? = nil
    @State private var tempCategoryId: String? = nil
    @State private var useDateRange: Bool = false
    @State private var tempStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var tempEndDate: Date = Date()
    
    var filteredCategoryOptions: [Category] {
        switch tempType {
        case .income:
            return categoryViewModel.incomeCategories
        case .expense:
            return categoryViewModel.expenseCategories
        case nil:
            return categoryViewModel.categories
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $tempType) {
                        Text("All").tag(CategoryType?.none)
                        Text("Income").tag(CategoryType?.some(.income))
                        Text("Expense").tag(CategoryType?.some(.expense))
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: tempType) { _ in
                        tempCategoryId = nil
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $tempCategoryId) {
                        Text("All Categories").tag(String?.none)
                        ForEach(filteredCategoryOptions) { category in
                            Text(category.name).tag(String?.some(category.id))
                        }
                    }
                }
                
                Section("Date Range") {
                    Toggle("Filter by Date", isOn: $useDateRange)
                    
                    if useDateRange {
                        // Future dates select hi na ho sakein - "in: ...Date()" ka matlab hai
                        // sabse purani date se lekar aaj tak (aage ki koi date allow nahi)
                        DatePicker("From", selection: $tempStartDate, in: ...Date(), displayedComponents: .date)
                        DatePicker("To", selection: $tempEndDate, in: ...Date(), displayedComponents: .date)
                        
                        Text("Future dates cannot be selected")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Section {
                    Button("Clear All Filters") {
                        tempType = nil
                        tempCategoryId = nil
                        useDateRange = false
                    }
                    .foregroundColor(AppTheme.expenseRed)
                }
            }
            .navigationTitle("Filter Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.filterType = tempType
                        viewModel.filterCategoryId = tempCategoryId
                        
                        if useDateRange {
                            viewModel.filterStartDate = min(tempStartDate, tempEndDate)
                            viewModel.filterEndDate = max(tempStartDate, tempEndDate)
                        } else {
                            viewModel.filterStartDate = nil
                            viewModel.filterEndDate = nil
                        }
                        
                        viewModel.applyFilters()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                tempType = viewModel.filterType
                tempCategoryId = viewModel.filterCategoryId
                if let start = viewModel.filterStartDate, let end = viewModel.filterEndDate {
                    useDateRange = true
                    tempStartDate = start
                    tempEndDate = end
                }
                
                if let uid = authViewModel.currentUser?.id {
                    categoryViewModel.setUserId(uid)
                    Task { await categoryViewModel.fetchCategories() }
                }
            }
        }
    }
}
