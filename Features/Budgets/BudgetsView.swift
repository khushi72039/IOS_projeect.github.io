import SwiftUI

struct BudgetsView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedItem: BudgetProgress? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.budgetItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("No expense categories found")
                            .font(.headline)
                        Text("Add categories first to set budgets")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.budgetItems) { item in
                            BudgetRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItem = item
                                }
                        }
                    }
                }
            }
            .navigationTitle("Budgets")
            .sheet(item: $selectedItem) { item in
                SetBudgetLimitView(viewModel: viewModel, item: item)
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
                    Task { await viewModel.loadBudgets() }
                }
            }
        }
    }
}

// MARK: - Budget Row with Progress Bar
struct BudgetRow: View {
    let item: BudgetProgress
    
    var progressColor: Color {
        switch item.statusColor {
        case "red": return AppTheme.expenseRed
        case "yellow": return AppTheme.warningAmber
        default: return AppTheme.incomeGreen
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: item.category.iconName)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color(hex: item.category.colorHex))
                    .clipShape(Circle())
                
                Text(item.category.name)
                    .font(.subheadline.bold())
                
                Spacer()
                
                if item.hasBudgetSet {
                    Text("₹\(item.spent, specifier: "%.0f") / ₹\(item.limit, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Not set")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            if item.hasBudgetSet {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.fieldBackground)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(progressColor)
                            .frame(width: geo.size.width * item.percentUsed, height: 10)
                    }
                }
                .frame(height: 10)
                
                // Accessibility: color ke alawa text se bhi status batana (colorblind users ke liye)
                Text("\(Int(item.percentUsed * 100))% used")
                    .font(.caption2)
                    .foregroundColor(progressColor)
            }
        }
        .padding(.vertical, 6)
    }
}
