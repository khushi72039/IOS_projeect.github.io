import SwiftUI

struct TransactionsListView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddSheet = false
    @State private var showFilterSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("No transactions yet")
                            .font(.headline)
                        Text("Tap + to add your first transaction")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("No matching transactions")
                            .font(.headline)
                        Text("Try adjusting your search, filters, or selected month")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.filteredGroupedTransactions, id: \.date) { group in
                            Section(group.date) {
                                ForEach(group.items) { transaction in
                                    TransactionListRow(transaction: transaction)
                                        .swipeActions {
                                            Button("Delete", role: .destructive) {
                                                Task { await viewModel.deleteTransaction(transaction) }
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search by category or note")
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: viewModel.isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(AppTheme.primaryIndigo)
                    }
                }
                ToolbarItem(placement: .principal) {
                    MonthSelectorView(selectedOption: $viewModel.selectedMonthOption, options: viewModel.monthOptions)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primaryIndigo)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTransactionView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showFilterSheet) {
                TransactionFilterView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            }
            .overlay(alignment: .top) {
                if let toast = viewModel.toastMessage {
                    ToastView(message: toast)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(), value: viewModel.toastMessage)
                }
            }
            .onAppear {
                if let uid = authViewModel.currentUser?.id {
                    viewModel.setUserId(uid)
                    Task { await viewModel.fetchTransactions() }
                }
            }
        }
    }
}

struct TransactionListRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: transaction.categoryIcon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: transaction.categoryColorHex))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.categoryName)
                    .font(.subheadline.bold())
                if let note = transaction.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text("\(transaction.type == .income ? "+" : "-")₹\(transaction.amount, specifier: "%.0f")")
                .font(.subheadline.bold())
                .foregroundColor(transaction.type == .income ? AppTheme.incomeGreen : AppTheme.expenseRed)
        }
        .padding(.vertical, 4)
    }
}
