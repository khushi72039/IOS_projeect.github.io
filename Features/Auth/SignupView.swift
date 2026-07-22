import SwiftUI

struct SignupView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    let currencies = ["INR", "USD", "EUR", "GBP"]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppTheme.deepBackground
                    .ignoresSafeArea()
                
                AppTheme.decorativeGradient
                    .frame(height: 220)
                    .clipShape(
                        RoundedCorner(radius: 40, corners: [.bottomLeft, .bottomRight])
                    )
                    .ignoresSafeArea(edges: .top)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 76, height: 76)
                                Image(systemName: "person.badge.plus.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 38, height: 38)
                                    .foregroundStyle(.white)
                            }
                            .padding(.top, 50)
                            
                            Text("Create Account")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Start your financial journey today")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        
                        VStack(spacing: 16) {
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppTheme.primaryIndigo)
                                    .frame(width: 20)
                                TextField("Full Name", text: $viewModel.name)
                            }
                            .padding()
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(AppTheme.primaryIndigo)
                                    .frame(width: 20)
                                TextField("Email", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding()
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(AppTheme.primaryIndigo)
                                    .frame(width: 20)
                                SecureField("Password", text: $viewModel.password)
                            }
                            .padding()
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.rotation")
                                    .foregroundColor(AppTheme.primaryIndigo)
                                    .frame(width: 20)
                                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            }
                            .padding()
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Currency")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                Picker("Currency", selection: $viewModel.selectedCurrency) {
                                    ForEach(currencies, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Button {
                                Task { await viewModel.signUp() }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Sign Up")
                                        .font(.headline)
                                        .foregroundColor(.black.opacity(0.85))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .background(AppTheme.ctaGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .disabled(viewModel.isLoading)
                        }
                        .padding(24)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.1), radius: 20, y: 8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .overlay(alignment: .top) {
                if let toast = viewModel.toastMessage {
                    ToastView(message: toast)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(), value: viewModel.toastMessage)
                }
            }
        }
    }
}
