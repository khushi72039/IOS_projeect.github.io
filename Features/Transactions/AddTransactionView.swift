import SwiftUI

struct AddTransactionView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @StateObject private var categoryViewModel = CategoryViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var filteredCategories: [Category] {
        viewModel.selectedType == .income ? categoryViewModel.incomeCategories : categoryViewModel.expenseCategories
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $viewModel.selectedType) {
                        Text("Expense").tag(CategoryType.expense)
                        Text("Income").tag(CategoryType.income)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.selectedType) { _ in
                        viewModel.selectedCategory = nil
                    }
                }
                
                Section("Amount") {
                    TextField("0", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2.bold())
                }
                
                Section("Category") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(filteredCategories) { category in
                            VStack(spacing: 6) {
                                Image(systemName: category.iconName)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 46, height: 46)
                                    .background(Color(hex: category.colorHex))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(AppTheme.primaryIndigo, lineWidth: viewModel.selectedCategory?.id == category.id ? 3 : 0)
                                            .padding(-3)
                                    )
                                
                                Text(category.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .onTapGesture {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Date") {
                    DatePicker("Transaction Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                }
                
                Section("Note (Optional)") {
                    TextField("Add a note...", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.addTransaction()
                            if success { dismiss() }
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if let uid = authViewModel.currentUser?.id {
                    categoryViewModel.setUserId(uid)
                    Task { await categoryViewModel.fetchCategories() }
                }
            }
        }
    }
}
