import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showSignup = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppTheme.deepBackground
                    .ignoresSafeArea()
                
                
                AppTheme.decorativeGradient
                    .frame(height: 260)
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
                                    .frame(width: 84, height: 84)
                                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 52, height: 52)
                                    .foregroundStyle(.white)
                            }
                            .padding(.top, 60)
                            
                            Text("Welcome Back")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Track. Budget. Grow.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        
                        
                        VStack(spacing: 18) {
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(AppTheme.primaryIndigo)
                                    .frame(width: 20)
                                TextField("Email", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .accessibilityLabel("Email address")
                            }
                            .padding()
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(AppTheme.primaryIndigo)
                                    .frame(width: 20)
                                SecureField("Password", text: $viewModel.password)
                                    .accessibilityLabel("Password")
                            }
                            .padding()
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Button {
                                Task { await viewModel.logIn() }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Login")
                                        .font(.headline)
                                        .foregroundColor(.black.opacity(0.85))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .background(AppTheme.ctaGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .disabled(viewModel.isLoading)
                            
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.footnote.bold())
                            .foregroundColor(AppTheme.primaryIndigo)
                            
                            HStack {
                                VStack { Divider() }
                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                VStack { Divider() }
                            }
                            .padding(.vertical, 4)
                            
                            Button {
                                Task { await viewModel.signInWithGoogle() }
                            } label: {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Sign in with Google")
                                        .font(.headline)
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .disabled(viewModel.isLoading)
                        }
                        .padding(24)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.1), radius: 20, y: 8)
                        .padding(.horizontal, 20)
                        
                        Button {
                            showSignup = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(.primary.opacity(0.7))
                                Text("Sign Up")
                                    .foregroundColor(AppTheme.primaryIndigo)
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                    }
                }
            }
            .sheet(isPresented: $showSignup) {
                SignupView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
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

// MARK: - Helper Shape for rounded top corners
struct RoundedCorner: Shape {
    var radius: CGFloat = 25
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
