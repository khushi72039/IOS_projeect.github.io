import SwiftUI

struct RecurringRulesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var rules: [RecurringRule] = []
    @State private var isLoading = true
    
    private let repository = RecurringRuleRepository()
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if rules.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "repeat.circle")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("No recurring transactions")
                            .font(.headline)
                        Text("Enable 'Make this recurring' when adding a transaction")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(rules) { rule in
                            HStack(spacing: 14) {
                                Image(systemName: rule.categoryIcon)
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color(hex: rule.categoryColorHex))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rule.categoryName)
                                        .font(.subheadline.bold())
                                    Text("\(rule.frequency.displayName) • ₹\(Int(rule.amount))")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { rule.isActive },
                                    set: { newValue in
                                        toggleRule(rule, isActive: newValue)
                                    }
                                ))
                                .labelsHidden()
                            }
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    deleteRule(rule)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recurring Transactions")
            .onAppear {
                Task { await loadRules() }
            }
        }
    }
    
    private func loadRules() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        isLoading = true
        rules = (try? await repository.fetchAllRules(userId: userId)) ?? []
        isLoading = false
    }
    
    private func toggleRule(_ rule: RecurringRule, isActive: Bool) {
        guard let userId = authViewModel.currentUser?.id else { return }
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].isActive = isActive
        }
        Task {
            try? await repository.setActive(userId: userId, ruleId: rule.id, isActive: isActive)
        }
    }
    
    private func deleteRule(_ rule: RecurringRule) {
        guard let userId = authViewModel.currentUser?.id else { return }
        rules.removeAll { $0.id == rule.id }
        Task {
            try? await repository.deleteRule(userId: userId, ruleId: rule.id)
        }
    }
}
