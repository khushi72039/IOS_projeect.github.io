import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showLogoutConfirm = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    Button {
                        showEditProfile = true
                    } label: {
                        HStack(spacing: 14) {
                            if let image = viewModel.profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.primaryIndigo.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    Text(viewModel.name.prefix(1).uppercased())
                                        .font(.title3.bold())
                                        .foregroundColor(AppTheme.primaryIndigo)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(authViewModel.currentUser?.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
                
                // Preferences Section
                Section("Preferences") {
                    HStack {
                        Label("Currency", systemImage: "dollarsign.circle")
                        Spacer()
                        Text(viewModel.currencyCode)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Toggle(isOn: $viewModel.notificationsEnabled) {
                        Label("Budget Notifications", systemImage: "bell.badge")
                    }
                    .tint(AppTheme.primaryIndigo)
                }
                
                // Widget Section - Daily Spending Limit
                Section {
                    HStack {
                        Label("Daily Spending Limit", systemImage: "square.grid.3x3.fill")
                        Spacer()
                        TextField("500", text: $viewModel.dailySpendingLimitText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: viewModel.dailySpendingLimitText) { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                viewModel.dailySpendingLimitText = String(filtered.prefix(6))
                            }
                        Button("Save") {
                            Task { await viewModel.updateDailySpendingLimit() }
                        }
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.primaryIndigo)
                    }
                } footer: {
                    Text("Used by your Home Screen Widget to show daily spending intensity")
                }
                
                // Manage Section
                Section("Manage") {
                    NavigationLink {
                        CategoriesView()
                            .environmentObject(authViewModel)
                    } label: {
                        Label("Manage Categories", systemImage: "tag")
                    }
                    
                    NavigationLink {
                        ExportView()
                            .environmentObject(authViewModel)
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink {
                        RecurringRulesView()
                            .environmentObject(authViewModel)
                    } label: {
                        Label("Recurring Transactions", systemImage: "repeat.circle")
                    }
                    
                    HStack {
                        Label("Sync Status", systemImage: "icloud.and.arrow.up")
                        Spacer()
                        Text("Up to date")
                            .font(.caption)
                            .foregroundColor(AppTheme.incomeGreen)
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Label("App Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                // Logout Section
                Section {
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Logout")
                                .foregroundColor(AppTheme.expenseRed)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showEditProfile, onDismiss: {
                if let updated = viewModel.updatedUser {
                    authViewModel.currentUser = updated
                }
            }) {
                EditProfileView(viewModel: viewModel)
            }
            .alert("Logout", isPresented: $showLogoutConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    authViewModel.logOut()
                }
            } message: {
                Text("Are you sure you want to logout?")
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
                if let user = authViewModel.currentUser {
                    viewModel.loadUser(user)
                }
            }
        }
    }
}
