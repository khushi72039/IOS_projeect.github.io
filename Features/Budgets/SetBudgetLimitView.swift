import SwiftUI

struct SetBudgetLimitView: View {
    @ObservedObject var viewModel: BudgetViewModel
    let item: BudgetProgress
    @Environment(\.dismiss) private var dismiss
    @State private var limitText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: item.category.iconName)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color(hex: item.category.colorHex))
                            .clipShape(Circle())
                        Text(item.category.name)
                            .font(.headline)
                    }
                }
                
                Section("Monthly Budget Limit") {
                    TextField("Enter amount", text: $limitText)
                        .keyboardType(.numberPad)
                        .font(.title2.bold())
                        .onChange(of: limitText) { newValue in
                            // Sirf digits allow karo, aur zyada se zyada 8 digits (99,999,999 tak)
                            let filtered = newValue.filter { $0.isNumber }
                            limitText = String(filtered.prefix(8))
                        }
                    
                    Text("Maximum limit: ₹9,99,99,999")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Set Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            guard let limit = Double(limitText), limit > 0 else {
                                viewModel.errorMessage = "Please enter a valid number"
                                return
                            }
                            let success = await viewModel.setBudgetLimit(for: item.category, limit: limit)
                            if success { dismiss() }
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if item.hasBudgetSet {
                    limitText = String(format: "%.0f", item.limit)
                }
            }
        }
    }
}
