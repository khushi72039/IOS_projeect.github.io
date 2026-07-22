//
//  ChartsView..swift
//  Finace_tracker_khushi
//
//  Created by Mobile5 on 22/07/26.
//

import SwiftUI
import Charts

struct ChartsView: View {
    @StateObject private var viewModel = ChartsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 60)
                } else {
                    // Bar Chart Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 6 Months Trend")
                            .font(.headline)
                        
                        if viewModel.monthlyTotals.isEmpty {
                            Text("No data available yet")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        } else {
                            Chart(viewModel.monthlyTotals) { item in
                                BarMark(
                                    x: .value("Month", item.monthLabel),
                                    y: .value("Amount", item.income)
                                )
                                .foregroundStyle(AppTheme.incomeGreen)
                                .position(by: .value("Type", "Income"))
                                
                                BarMark(
                                    x: .value("Month", item.monthLabel),
                                    y: .value("Amount", item.expense)
                                )
                                .foregroundStyle(AppTheme.expenseRed)
                                .position(by: .value("Type", "Expense"))
                            }
                            .frame(height: 220)
                            
                            HStack(spacing: 16) {
                                LegendDot(color: AppTheme.incomeGreen, label: "Income")
                                LegendDot(color: AppTheme.expenseRed, label: "Expense")
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Donut Chart Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Category Breakdown")
                                .font(.headline)
                            Spacer()
                            Picker("Month", selection: $viewModel.selectedMonthOffset) {
                                ForEach(viewModel.availableMonths, id: \.offset) { month in
                                    Text(month.label).tag(month.offset)
                                }
                            }
                            .onChange(of: viewModel.selectedMonthOffset) { _ in
                                viewModel.onMonthChanged()
                            }
                        }
                        
                        if viewModel.categoryBreakdown.isEmpty {
                            Text("No expenses recorded for this month")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                        } else {
                            DonutChartView(slices: viewModel.categoryBreakdown)
                                .frame(height: 220)
                            
                            VStack(spacing: 8) {
                                ForEach(viewModel.categoryBreakdown) { slice in
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: slice.colorHex))
                                            .frame(width: 10, height: 10)
                                        Text(slice.name)
                                            .font(.caption)
                                        Spacer()
                                        Text("\(Int(slice.percentage * 100))%")
                                            .font(.caption.bold())
                                        Text("₹\(slice.amount, specifier: "%.0f")")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .padding(.top, 12)
        }
        .navigationTitle("Charts & Trends")
        .onAppear {
            if let uid = authViewModel.currentUser?.id {
                viewModel.setUserId(uid)
                Task { await viewModel.loadChartsData() }
            }
        }
    }
}

// MARK: - Custom Donut Chart (iOS 16 compatible - SectorMark ke bina)
struct DonutChartView: View {
    let slices: [CategorySlice]
    
    var body: some View {
        ZStack {
            ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                Circle()
                    .trim(from: startAngle(for: index), to: endAngle(for: index))
                    .stroke(Color(hex: slice.colorHex), style: StrokeStyle(lineWidth: 32, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
            
            VStack(spacing: 2) {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Text("₹\(slices.reduce(0) { $0 + $1.amount }, specifier: "%.0f")")
                    .font(.headline.bold())
            }
        }
        .padding(20)
    }
    
    private func startAngle(for index: Int) -> CGFloat {
        let precedingTotal = slices.prefix(index).reduce(0) { $0 + $1.percentage }
        return precedingTotal
    }
    
    private func endAngle(for index: Int) -> CGFloat {
        startAngle(for: index) + slices[index].percentage
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundColor(AppTheme.textSecondary)
        }
    }
}
