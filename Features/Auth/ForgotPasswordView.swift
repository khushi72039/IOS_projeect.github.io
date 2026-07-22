//
//  ForgotPasswordView.swift
//  Finace_tracker_khushi
//
//  Created by Mobile5 on 09/07/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var successMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Reset Password")
                .font(.title.bold())
            
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            if let success = successMessage {
                Text(success).foregroundColor(.green).font(.caption)
            }
            if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red).font(.caption)
            }
            
            Button {
                Task {
                    let success = await viewModel.resetPassword()
                    if success {
                        successMessage = "Password reset link has been sent to your email"
                    }
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Send Reset Link").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
