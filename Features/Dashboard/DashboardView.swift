import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Greeting Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello, \(viewModel.userName) 👋")
                                .font(.title2.bold())
                            Text("Here's your financial overview")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "bell.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.primaryIndigo)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else {
                        // Balance Hero Card
                        VStack(spacing: 16) {
                            Text("Net Balance (This Month)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("₹\(viewModel.netBalance, specifier: "%.0f")")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Divider().background(Color.white.opacity(0.3))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundColor(AppTheme.incomeGreen)
                                        Text("Income")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Text("₹\(viewModel.totalIncome, specifier: "%.0f")")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text("Expense")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundColor(AppTheme.expenseRed)
                                    }
                                    Text("₹\(viewModel.totalExpense, specifier: "%.0f")")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(24)
                        .background(AppTheme.heroCardGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: AppTheme.primaryIndigo.opacity(0.3), radius: 15, y: 8)
                        .padding(.horizontal)
                        
                        // Budget Alert Banner (conditional - Budget Model bante hi enable hoga)
                        if viewModel.isBudgetAlertVisible {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.warningAmber)
                                Text(viewModel.budgetAlertMessage)
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(AppTheme.warningAmber.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal)
                        }
                        
                        
                        // Quick Actions
                                                HStack(spacing: 16) {
                                                    QuickActionButton(icon: "plus.circle.fill", label: "Add Income", color: AppTheme.incomeGreen)
                                                    QuickActionButton(icon: "minus.circle.fill", label: "Add Expense", color: AppTheme.expenseRed)
                                                    
                                                    NavigationLink {
                                                        ChartsView()
                                                    } label: {
                                                        QuickActionButton(icon: "chart.pie.fill", label: "Reports", color: AppTheme.primaryIndigo)
                                                    }
                                                }
                                                .padding(.horizontal)
                        
                        // Top Categories
                        if !viewModel.topCategories.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Top Spending Categories")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(viewModel.topCategories) { category in
                                            CategoryCard(category: category)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Recent Transactions
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Transactions")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            if viewModel.recentTransactions.isEmpty {
                                Text("No transactions yet. Add your first one!")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(viewModel.recentTransactions) { txn in
                                        DashboardTransactionRow(transaction: txn)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.loadDashboardData()
            }
            .onAppear {
                viewModel.setUserName(authViewModel.currentUser?.name ?? "User")
                if let uid = authViewModel.currentUser?.id {
                    viewModel.setUserId(uid)
                    Task { await viewModel.loadDashboardData() }
                }
            }
        }
    }
}

// MARK: - Reusable Components

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 54, height: 54)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            Text(label)
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryCard: View {
    let category: CategorySpend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: category.iconName)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: category.colorHex))
                .clipShape(Circle())
            
            Text(category.name)
                .font(.subheadline.bold())
            
            Text("₹\(category.amount, specifier: "%.0f")")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding()
        .frame(width: 130, alignment: .leading)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DashboardTransactionRow: View {
    let transaction: RecentTransaction
    
    var isIncome: Bool { transaction.amount > 0 }
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: transaction.iconName)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: transaction.colorHex))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline.bold())
                Text(transaction.category)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(isIncome ? "+" : "")₹\(transaction.amount, specifier: "%.0f")")
                    .font(.subheadline.bold())
                    .foregroundColor(isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed)
                Text(transaction.date)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
