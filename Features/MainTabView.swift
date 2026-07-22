import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            TransactionsListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            
            BudgetsView()
                            .tabItem {
                                Label("Budgets", systemImage: "chart.pie.fill")
                            }
            
            Text("AI Coach - Coming Soon")
                .tabItem {
                    Label("Coach", systemImage: "sparkles")
                }
            
            SettingsPlaceholderView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.primaryIndigo)
    }
}

// Temporary Settings placeholder jisme Logout button hai (asli Settings screen baad me banega)
struct SettingsPlaceholderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Manage Categories") {
                    CategoriesView()
                        .environmentObject(authViewModel)
                }
                
                Button("Logout") {
                    authViewModel.logOut()
                }
                .foregroundColor(AppTheme.expenseRed)
            }
            .navigationTitle("Settings")
        }
    }
}
