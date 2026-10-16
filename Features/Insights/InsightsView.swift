import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showGoalEditor = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // Financial Score Gauge
                            VStack(spacing: 12) {
                                Text("Financial Score")
                                    .font(.headline)
                                
                                ScoreGaugeView(score: viewModel.financialScore)
                                    .frame(width: 160, height: 160)
                                
                                Text(viewModel.scoreLabel)
                                    .font(.subheadline.bold())
                                    .foregroundColor(scoreColor)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(scoreColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            
                            // Smart Suggestions
                            if !viewModel.suggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Smart Suggestions")
                                        .font(.headline)
                                    
                                    ForEach(viewModel.suggestions, id: \.self) { tip in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "lightbulb.fill")
                                                .foregroundColor(AppTheme.warningAmber)
                                                .padding(.top, 2)
                                            Text(tip)
                                                .font(.subheadline)
                                        }
                                        .padding()
                                        .background(AppTheme.fieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Spending Habits
                            InsightSectionCard(title: "Spending Habits") {
                                InsightRow(label: "Top Category", value: viewModel.topCategoryName)
                                InsightRow(label: "Average Transaction", value: "₹\(Int(viewModel.averageTransactionSize))")
                                InsightRow(label: "Most Spending Day", value: viewModel.mostSpendingDay)
                            }
                            
                            // Budget Health
                            InsightSectionCard(title: "Budget Health") {
                                InsightRow(label: "Categories Near/Over Limit", value: "\(viewModel.categoriesNearLimit) of \(viewModel.totalBudgetedCategories)")
                                InsightRow(label: "Overall Adherence", value: "\(Int(viewModel.budgetAdherencePercent))%")
                            }
                            
                            // Savings Analysis
                            InsightSectionCard(title: "Savings Analysis") {
                                InsightRow(label: "This Month's Savings Rate", value: "\(Int(viewModel.savingsRate))%")
                                InsightRow(label: "Your Goal", value: "\(Int(viewModel.savingsGoalPercent))%")
                                
                                Button("Edit Savings Goal") {
                                    showGoalEditor = true
                                }
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.primaryIndigo)
                                .padding(.top, 4)
                            }
                            
                            // Monthly Comparison
                            if !viewModel.categoryComparisons.isEmpty {
                                InsightSectionCard(title: "This Month vs Last Month") {
                                    ForEach(viewModel.categoryComparisons.prefix(5)) { comparison in
                                        HStack {
                                            Text(comparison.categoryName)
                                                .font(.subheadline)
                                            Spacer()
                                            HStack(spacing: 4) {
                                                Image(systemName: comparison.percentChange >= 0 ? "arrow.up" : "arrow.down")
                                                    .font(.caption2)
                                                Text("\(Int(abs(comparison.percentChange)))%")
                                                    .font(.caption.bold())
                                            }
                                            .foregroundColor(comparison.percentChange >= 0 ? AppTheme.expenseRed : AppTheme.incomeGreen)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showGoalEditor) {
                SavingsGoalEditorView(viewModel: viewModel)
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
                    Task { await viewModel.loadInsights() }
                }
            }
        }
    }
    
    var scoreColor: Color {
        if viewModel.financialScore >= 75 { return AppTheme.incomeGreen }
        if viewModel.financialScore >= 50 { return AppTheme.warningAmber }
        return AppTheme.expenseRed
    }
}

// MARK: - Reusable Components

struct ScoreGaugeView: View {
    let score: Int
    
    var progressColor: Color {
        if score >= 75 { return AppTheme.incomeGreen }
        if score >= 50 { return AppTheme.warningAmber }
        return AppTheme.expenseRed
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.fieldBackground, lineWidth: 16)
            
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: score)
            
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("/ 100")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

struct InsightSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

struct InsightRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

struct SavingsGoalEditorView: View {
    @ObservedObject var viewModel: InsightsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var goalText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Set Your Monthly Savings Goal (%)") {
                    TextField("e.g. 20", text: $goalText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Savings Goal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let value = Double(goalText) {
                            Task {
                                await viewModel.updateSavingsGoal(value)
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                goalText = String(format: "%.0f", viewModel.savingsGoalPercent)
            }
        }
    }
}
