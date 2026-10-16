import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: Int = 0
    @State private var dashboardPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(path: $dashboardPath)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            TransactionsListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
                .tag(1)
            
            BudgetsView()
                .tabItem {
                    Label("Budgets", systemImage: "chart.pie.fill")
                }
                .tag(2)
            
            ChartsView()
                .tabItem {
                    Label("Charts", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(AppTheme.primaryIndigo)
        .onChange(of: selectedTab) { newValue in
            if newValue == 0 {
                dashboardPath = NavigationPath()
            }
        }
        .task {
            // App launch hote hi due recurring transactions generate karo
            if let uid = authViewModel.currentUser?.id {
                await RecurringEngine.shared.processRecurringRules(userId: uid)
            }
        }
    }
}
