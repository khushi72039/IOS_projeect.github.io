import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.categories.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "tag.slash")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("No categories yet")
                            .font(.headline)
                        Text("Tap + to add your first category")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("Expense Categories") {
                            ForEach(viewModel.expenseCategories) { category in
                                CategoryRow(category: category)
                                    .swipeActions {
                                        if !category.isDefault {
                                            Button("Delete", role: .destructive) {
                                                Task { await viewModel.deleteCategory(category) }
                                            }
                                        }
                                    }
                            }
                        }
                        
                        Section("Income Categories") {
                            ForEach(viewModel.incomeCategories) { category in
                                CategoryRow(category: category)
                                    .swipeActions {
                                        if !category.isDefault {
                                            Button("Delete", role: .destructive) {
                                                Task { await viewModel.deleteCategory(category) }
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
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
                AddCategoryView(viewModel: viewModel)
            }
            .onAppear {
                if let uid = authViewModel.currentUser?.id {
                    viewModel.setUserId(uid)
                    Task { await viewModel.fetchCategories() }
                }
            }
        }
    }
}

// MARK: - Category Row Component
struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: category.iconName)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: category.colorHex))
                .clipShape(Circle())
            
            Text(category.name)
                .font(.subheadline)
            
            Spacer()
            
            if category.isDefault {
                Text("Default")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.fieldBackground)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Hex Color Helper
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
